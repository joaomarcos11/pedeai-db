# pedeai-db

Repository to provision AWS RDS database using Terraform.

### How to use

#### Github Actions

- Configure the repository secrets.
- PR to main branch or go to actions and manually run **Provision AWS RDS database** Github Action.

#### Locally

With **terraform** and **aws CLI** installed.

Configure aws credentials:

- edit `~/.aws/credentials` file

To create EKS cluster:

- `terraform init` to initialize
- `terraform plan` to plan deploy
- `terraform apply` to create resources

To destroy:

- `terraform destroy` to destroy resources