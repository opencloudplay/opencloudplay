resource "aws_vpc" "opencloudplay" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.namespace}"
  }
}

resource "aws_subnet" "opencloudplay" {
  vpc_id     = aws_vpc.opencloudplay.id
  cidr_block = var.subnet_cidr
  availability_zone = var.zone
  tags = {
    Name = "subnet-${var.namespace}"
  }
}

resource "aws_internet_gateway" "opencloudplay" {
  vpc_id = aws_vpc.opencloudplay.id
  tags = {
    Name = "igw-${var.namespace}"
  }
}

resource "aws_route_table" "opencloudplay" {
  vpc_id = aws_vpc.opencloudplay.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.opencloudplay.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.opencloudplay.id
}

resource "aws_eip" "opencloudplay" {
  instance = aws_instance.opencloudplay.id

  tags = {
    Name = "EIPForWindowsGPUInstance"
  }
}