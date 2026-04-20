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
# ========================
# SECURITY GROUPS
# ========================

# Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "techcorp-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techcorp-bastion-sg"
  }
}
# Web Security Group
resource "aws_security_group" "web_sg" {
  name        = "techcorp-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH from Bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techcorp-web-sg"
  }
}
# Database Security Group
resource "aws_security_group" "db_sg" {
  name        = "techcorp-db-sg"
  description = "Security group for database server"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description     = "Postgres from Web SG only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH from Bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techcorp-db-sg"
  }
}
# ========================
# BASTION HOST
# ========================
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type_bastion
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  tags = {
    Name = "techcorp-bastion"
  }
}

# Elastic IP for Bastion
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "techcorp-bastion-eip"
  }
}

# ========================
# WEB SERVERS
# ========================
resource "aws_instance" "web_server_1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name

  user_data = file("user_data/web_server_setup.sh")

  tags = {
    Name = "techcorp-web-server-1"
  }
}

resource "aws_instance" "web_server_2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_web
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair_name

  user_data = file("user_data/web_server_setup.sh")

  tags = {
    Name = "techcorp-web-server-2"
  }
}

# ========================
# DATABASE SERVER
# ========================
resource "aws_instance" "db_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_db
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_pair_name

  user_data = file("user_data/db_server_setup.sh")

  tags = {
    Name = "techcorp-db-server"
  }
}
# ========================
# APPLICATION LOAD BALANCER
# ========================
resource "aws_lb" "techcorp_alb" {
  name               = "techcorp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "techcorp-alb"
  }
}

# ========================
# TARGET GROUP
# ========================
resource "aws_lb_target_group" "techcorp_tg" {
  name     = "techcorp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "techcorp-tg"
  }
}

# ========================
# TARGET GROUP ATTACHMENTS
# ========================
resource "aws_lb_target_group_attachment" "web_server_1" {
  target_group_arn = aws_lb_target_group.techcorp_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_server_2" {
  target_group_arn = aws_lb_target_group.techcorp_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# ========================
# ALB LISTENER
# ========================
resource "aws_lb_listener" "techcorp_listener" {
  load_balancer_arn = aws_lb.techcorp_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.techcorp_tg.arn
  }
}