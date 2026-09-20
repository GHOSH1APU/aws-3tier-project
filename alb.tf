# 1. The Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "3-tier-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.networking.public_subnets
}

# 2. Target Group (Routes traffic to the App Servers)
resource "aws_lb_target_group" "app_tg" {
  name     = "3-tier-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.networking.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# 3. ALB Listener (Listens on port 80 and forwards to the Target Group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "The DNS name of the ALB to access the web application"
}