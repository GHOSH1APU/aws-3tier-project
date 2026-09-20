# 1. Create a DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "tier-3-db-subnet-group"
  subnet_ids = module.networking.private_db_subnets

  tags = {
    Name = "tier-3-db-subnet-group"
  }
}

# 2. Provision the MySQL RDS Instance
resource "aws_db_instance" "mysql" {
  identifier             = "tier3-mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  
  db_name                = "appdatabase"
  username               = "admin"
  password               = "password1234" # For practice only. In production, use AWS Secrets Manager.
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = "3-tier-mysql-db"
  }
}