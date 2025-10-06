Quick credential and run guide

If you deleted your old IAM credentials and created a new IAM user/keys, here are three ways to provide credentials to Terraform for this project.

1) Temporary PowerShell environment (session-only)

- Run the helper script in PowerShell to set env vars for this session:
  .\scripts\set-aws-creds.ps1 -AccessKey "<ACCESS_KEY>" -SecretKey "<SECRET_KEY>"

- Verify the credentials (requires AWS CLI):
  aws sts get-caller-identity

- Run Terraform:
  terraform init
  terraform plan -var-file=terraform.tfvars
  terraform apply -var-file=terraform.tfvars

2) Configure a named AWS CLI profile (recommended)

- With the AWS CLI installed, run:
  aws configure --profile cost-tracker

- Export the profile for Terraform in PowerShell before running Terraform:
  $env:AWS_PROFILE = 'cost-tracker'

- Or add to your environment variables permanently via Windows settings.

3) Shared credentials file (~/.aws/credentials) or environment variables

- You can also add credentials to %USERPROFILE%\.aws\credentials or use environment variables permanently.

Troubleshooting

- If Terraform shows access denied when using a backend (S3/DynamoDB), ensure the new IAM user has the right permissions to access the backend resources.
- You can run 'aws sts get-caller-identity' to confirm which AWS account and user the credentials belong to.

Notes specific to this repo

- The provider is configured in `provider.tf` to use region from `terraform.tfvars`.
- If you use an S3 backend (not present in the repo root), update the backend configuration with a profile or ensure the IAM user can access the backend bucket.
