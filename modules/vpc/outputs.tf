
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "public_subnets" {
  value = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
}

output "private_app_subnets" {
  value = [aws_subnet.private_app_1a.id, aws_subnet.private_app_1b.id]
}

output "private_db_subnets" {
  value = [aws_subnet.private_db_1a.id, aws_subnet.private_db_1b.id]
}