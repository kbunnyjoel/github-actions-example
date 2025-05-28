# Public route table with route to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.vpc.igw_id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate public subnet used by bastion with public route table
# resource "aws_route_table_association" "public_subnet" {
#   subnet_id      = module.vpc.public_subnets[0]
#   route_table_id = aws_route_table.public.id
# }
