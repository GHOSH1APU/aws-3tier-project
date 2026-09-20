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

  # Install a web server so the ALB target group health checks pass
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd mariadb105
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Tier 2 - Application Layer</h1>" > /var/www/html/index.html
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