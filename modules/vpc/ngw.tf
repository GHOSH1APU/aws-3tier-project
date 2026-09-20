# ==========================================
# NAT GATEWAY (For Private Subnets Internet Access)
# ==========================================
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "3-tier-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name = "3-tier-nat-gw"
  }
  depends_on = [aws_internet_gateway.igw]
}