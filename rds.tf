provider "aws" {
    region = local.region
}

locals {
    name = "my-postgres"
    region = "us-east-1"
}

resource "aws_db_instance" "myrds" {
    engine = "postgres"
    engine_version = "16"
    allocated_storage = 20
    instance_class = "db.t3.micro"
    storage_type = "gp2"
    identifier = "mydb"
    username = "pedeai"
    password = "senha1ABC" # TODO: puxar da secrets?
    publicly_accessible = false
    skip_final_snapshot = true
    
    tags =  {
        Name = "Myrdsdb"
    }
}
