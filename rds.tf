provider "aws" {
    region = "us-east-1"
}

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

provider "random" {
  version = ">= 3.1.0"
}

provider "null" {
  version = ">= 3.1.0"
}

data "aws_subnets" "db_subnets" {
  filter {
    name = "tag:Name"
    values = ["fiap44-private-us-east-1a", "fiap44-private-us-east-1b"]
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.db_subnets.ids)
  id       = each.value
}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["fiap44-vpc"]
  }
}

# Subnets creation
resource "aws_subnet" "private-a" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.0.9.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "fiap44-db-private-us-east-1a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "fiap44-db-private-us-east-1b"
  }
}

# DB instance will be deployed in the VPC
# where those subnets are deployed. If it 
# isn't especified, then the subnet_group
# is deploy in the default VPC
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  tags = {
    Name = "db-subnet-group"
  }
}


##########################################
## SECURITY GROUP AND INBOUND RULES
##################


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

resource "aws_db_instance" "rds-pg" {
  engine = "postgres"
  engine_version = "16"
  allocated_storage = 20
  instance_class = "db.t3.micro"
  storage_type = "gp2"
  identifier = "fiap44-db"
  db_name = "pedeai"
  username = "pedeai"
  password = "senha1ABC"
  publicly_accessible = true
  skip_final_snapshot = true
  
  tags =  {
      Name = "fiap44-db"
  }

  # Assign this instance to a specific VPC
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  # Assign group with the correct inbound rules
  vpc_security_group_ids = [aws_security_group.allow_node_group.id]

  depends_on = [aws_security_group.allow_node_group, aws_db_subnet_group.db_subnet_group]
}

# MongoDB Atlas setup
resource "mongodbatlas_project" "project" {
  name   = "my-mongodb-project"
  org_id = var.mongodb_atlas_org_id
}

resource "mongodbatlas_cluster" "cluster" {
  project_id   = mongodbatlas_project.project.id
  name         = "my-cluster"
  provider_name = "AWS"
  provider_region_name = "US_EAST_1"
  provider_instance_size_name = "M10"
  provider_backup_enabled = true
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "mongodbatlas_database_user" "db_user" {
  project_id    = mongodbatlas_project.project.id
  username      = "dbUser"
  password      = random_password.db_password.result
  roles {
    role_name     = "readWrite"
    database_name = "admin"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/mongodb/db_password"
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/mongodb/db_username"
  type  = "String"
  value = mongodbatlas_database_user.db_user.username
}

output "cluster_connection_string" {
  value = mongodbatlas_cluster.cluster.connection_strings.standard_srv
}

output "db_username" {
  value = mongodbatlas_database_user.db_user.username
}

output "db_password" {
  value = random_password.db_password.result
