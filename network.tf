data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tasklog-vpc"
  }
}

# Subnets
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "tasklog-public-0"
  }
}


resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "tasklog-public-1"
  }
}

resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.128.0/20"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "tasklog-private-1"
  }
}


resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.144.0/20"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "tasklog-private-1"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "tasklog-db"
  subnet_ids = [aws_subnet.public_0.id, aws_subnet.public_1.id]

  tags = {
    Name = "tasklog-db"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tasklog-igw"
  }
}

# Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "tasklog-public"
  }
}

resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
