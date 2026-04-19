terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}
# ========================
# VPC
# ========================
resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "techcorp-vpc"
  }
}
# ========================
# PUBLIC SUBNETS
# ========================
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "techcorp-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "techcorp-public-subnet-2"
  }
}

# ========================
# PRIVATE SUBNETS
# ========================
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "techcorp-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name = "techcorp-private-subnet-2"
  }
}
# ========================
# INTERNET GATEWAY
# ========================
resource "aws_internet_gateway" "techcorp_igw" {
  vpc_id = aws_vpc.techcorp_vpc.id

  tags = {
    Name = "techcorp-igw"
  }
}
# ========================
# ELASTIC IPs FOR NAT
# ========================
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"

  tags = {
    Name = "techcorp-nat-eip-1"
  }
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"

  tags = {
    Name = "techcorp-nat-eip-2"
  }
}

# ========================
# NAT GATEWAYS
# ========================
resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "techcorp-nat-gw-1"
  }

  depends_on = [aws_internet_gateway.techcorp_igw]
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "techcorp-nat-gw-2"
  }

  depends_on = [aws_internet_gateway.techcorp_igw]
}
# ========================
# PUBLIC ROUTE TABLE
# ========================
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.techcorp_igw.id
  }

  tags = {
    Name = "techcorp-public-rt"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ========================
# PRIVATE ROUTE TABLES
# ========================
resource "aws_route_table" "private_rt_1" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "techcorp-private-rt-1"
  }
}

resource "aws_route_table" "private_rt_2" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "techcorp-private-rt-2"
  }
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt_1.id
}

resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt_2.id
}