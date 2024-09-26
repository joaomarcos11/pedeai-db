# pedeai-db

Repository to provision an AWS RDS Postgres database onto an existing subnet/vpc using Terraform.

#### How to use

With *terraform* and *aws CLI* installed.

Configure aws credentials:

- edit `~/.aws/credentials` file

To create RDS database:

- `terraform init` to initialize
- `terraform plan` to plan deploy
- `terraform apply` to create resources

To destroy:

- `terraform destroy` to destroy resources