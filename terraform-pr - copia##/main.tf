provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    Proyecto    = var.proyecto
    Ambiente    = var.ambiente
    Responsable = var.responsable
  }

  subredes_publicas = [for k, v in aws_subnet.main : v.id if var.subredes[k].publica]
  subredes_privadas = [for k, v in aws_subnet.main : v.id if !var.subredes[k].publica]

  clase_rds = lookup({
    dev  = "db.t3.micro"
    prod = "db.t3.small"
  }, var.ambiente, "db.t3.micro")
}

data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# --- VPC Y SUBREDES ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = "vpc-${var.proyecto}-${var.ambiente}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "igw-${var.proyecto}" })
}

resource "aws_subnet" "main" {
  for_each                = var.subredes
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.publica

  tags = merge(local.common_tags, { Name = "subnet-${each.key}" })
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.common_tags, { Name = "rt-publica" })
}

resource "aws_route_table_association" "publica" {
  for_each       = { for k, v in var.subredes : k => v if v.publica }
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.publica.id
}

# --- SECURITY GROUPS ---
resource "aws_security_group" "web" {
  name   = "web-sg-s${var.ambiente}"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "sg-web" })
}

resource "aws_security_group" "rds" {
  name   = "rds-rb-ds${var.ambiente}"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  tags = merge(local.common_tags, { Name = "sg-rds" })
}

# --- SERVIDORES EC2 ---
resource "aws_instance" "servidores" {
  for_each               = var.servidores
  ami                    = data.aws_ami.linux.id
  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.main[each.value.subred].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y httpd mariadb105
              systemctl start httpd
              echo "Servidor: ${each.key} | Ambiente: ${var.ambiente}" > /var/www/html/index.html
              EOF

  root_block_device {
    volume_size = var.ambiente == "prod" ? each.value.disk_size * 2 : each.value.disk_size
  }

  tags = merge(local.common_tags, { Name = each.key })
}

# --- NETWORK LOAD BALANCER ---
resource "aws_lb" "nlb" {
  name               = "nlb-${var.proyecto}-${var.ambiente}"
  internal           = false
  load_balancer_type = "network"
  subnets            = local.subredes_publicas
  security_groups    = [aws_security_group.web.id]
  tags               = merge(local.common_tags, { Name = "nlb-biblioteca" })
}

resource "aws_lb_target_group" "tg" {
  name     = "tg-${var.proyecto}-${var.ambiente}"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "targets" {
  for_each         = aws_instance.servidores
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = each.value.id
  port             = 80
}

# --- BASE DE DATOS RDS ---
resource "aws_db_subnet_group" "rds" {
  name       = "sng-rds-${var.ambiente}"
  subnet_ids = local.subredes_privadas
  tags       = merge(local.common_tags, { Name = "sng-rds" })
}

resource "aws_db_instance" "mysql" {
  identifier             = "db-${var.proyecto}-${var.ambiente}"
  engine                 = "mysql"
  instance_class         = local.clase_rds
  allocated_storage      = 20
  db_name                = "bibliotecadb"
  username               = "admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  multi_az = var.ambiente == "prod" ? true : false

  tags = merge(local.common_tags, { Name = "rds-biblioteca" })
}

# --- BUCKET S3 ---
resource "aws_s3_bucket" "bucket" {
  bucket        = format("%s-%s-%s-2026-vv2026", var.proyecto, var.aplicacion, var.ambiente)
  force_destroy = true
  tags          = merge(local.common_tags, { Name = "bucket-biblioteca" })
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.ambiente == "prod" ? "Enabled" : "Suspended"
  }
}