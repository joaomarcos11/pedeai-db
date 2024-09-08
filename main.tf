provider "aws" {
    region = var.region_name
}

## NETWORK

data "aws_subnets" "db_subnets" {
    filter {
        name = "tag:Name"
        values = ["pedeai-private-us-east-1a", "pedeai-private-us-east-1b"]
    }
}

data "aws_subnet" "subnet" {
    for_each = toset(data.aws_subnets.db_subnets.ids)
    id = each.value
}

data "aws_vpc" "vpc" {
    filter {
        name = "tag:Name"
        values = ["pedeai-vpc"]
    }
}

resource "aws_subnet" "private-a" {
  vpc_id = data.aws_vpc.vpc.id
  cidr_block = "192.168.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-pedeai-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id = data.aws_vpc.vpc.id
  cidr_block = "192.168.9.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-pedeai-b"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
    name = "db-subnet-group-pedeai"
    subnet_ids = [ aws_subnet.private-a.id, aws_subnet.private-b.id ]

    tags = {
        Name = "db-subnet-group"
    }
}

## SECURITY

resource "aws_security_group" "allow_node_group" {
  name        = "allow_node_group"
  description = "Allow inbound traffic from the EKS node group"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name = "allow_node_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_node_group" {
  # Allow each subnet to access the RDS instance
  for_each          = data.aws_subnet.subnet
  security_group_id = aws_security_group.allow_node_group.id
  cidr_ipv4         = each.value.cidr_block
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

## DB

resource "aws_db_instance" "db" {
    engine = "postgres"
    engine_version = "16"
    allocated_storage = 20
    instance_class = "db.t3.micro"
    storage_type = "gp2"
    identifier = "mydb"
    username = var.username
    password = var.password
    publicly_accessible = false
    skip_final_snapshot = true
    apply_immediately = true
    
    tags =  {
        Name = "Myrdsdb"
    }
}
