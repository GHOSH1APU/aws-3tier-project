# 1. Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Create the Launch Template
resource "aws_launch_template" "app_lt" {
  name_prefix   = "3-tier-app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  # Attach the SSM Profile
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }
  # Install a web server so the ALB target group health checks pass
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd php php-mysqli mariadb105

              # Create the dynamic PHP application
              cat << 'PHP_EOF' > /var/www/html/index.php
              <?php
              $server_ip = $_SERVER['SERVER_ADDR'] ?? gethostbyname(gethostname());
              $server_host = gethostname();

              $servername = "${aws_db_instance.mysql.address}";
              $username = "admin";
              $password = "password1234";
              $dbname = "appdatabase";

              $conn = new mysqli($servername, $username, $password, $dbname);

              if ($conn->connect_error) {
                die("Connection failed: " . $conn->connect_error);
              }

              echo "<h1>Tier 2 App Server & Tier 3 Database</h1>";
              echo "<p><strong>Served by Node IP:</strong> " . htmlspecialchars($server_ip) . "</p>";
              echo "<p><strong>Node Hostname:</strong> " . htmlspecialchars($server_host) . "</p>";
              echo "<hr>";

              echo "<h3>Users Table Records</h3>";
              echo "<table border='1' cellpadding='5' cellspacing='0'>";
              echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>Timestamp</th></tr>";

              $sql = "SELECT id, name, email, created_at FROM users";
              $result = $conn->query($sql);

              if ($result && $result->num_rows > 0) {
                while($row = $result->fetch_assoc()) {
                  echo "<tr>";
                  echo "<td>" . htmlspecialchars($row["id"]) . "</td>";
                  echo "<td>" . htmlspecialchars($row["name"]) . "</td>";
                  echo "<td>" . htmlspecialchars($row["email"]) . "</td>";
                  echo "<td>" . htmlspecialchars($row["created_at"]) . "</td>";
                  echo "</tr>";
                }
              } else {
                echo "<tr><td colspan='4'>No users found</td></tr>";
              }
              echo "</table>";

              $conn->close();
              ?>
              PHP_EOF

              # Start and enable the Apache service
              systemctl start httpd
              systemctl enable httpd
              EOF
  )

  tags = {
    Name = "3-tier-app-lt"
  }
}

# 3. Create the Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "3-tier-app-asg"
  vpc_zone_identifier = module.networking.private_app_subnets
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "3-tier-app-instance"
    propagate_at_launch = true
  }
}
# 5. IAM Role for SSM Session Manager Access
resource "aws_iam_role" "ssm_role" {
  name = "tier2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "tier2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}