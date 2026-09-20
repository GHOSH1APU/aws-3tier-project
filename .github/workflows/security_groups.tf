# 1. ALB Security Group (Tier 1 - Internet Facing)
resource "aws_security_group" "alb_sg" {
  name        = "3-tier-alb-sg"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "3-tier-alb-sg" }
}

# 2. App Server Security Group (Tier 2 - Private Compute)
resource "aws_security_group" "app_sg" {
  name        = "3-tier-app-sg"
  description = "Allow inbound traffic ONLY from the ALB"
  vpc_id      = module.networking.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80 
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "3-tier-app-sg" }
}

# 3. Database Security Group (Tier 3 - Private Data)
resource "aws_security_group" "db_sg" {
  name        = "3-tier-db-sg"
  description = "Allow inbound database traffic ONLY from App Servers"
  vpc_id      = module.networking.vpc_id

  ingress {
    description     = "Database connection from App Servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "3-tier-db-sg" }
}