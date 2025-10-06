<#
PowerShell helper to set AWS credentials for the current session

Usage (temporary session variables):
  .\scripts\set-aws-creds.ps1 -AccessKey <key> -SecretKey <secret> [-SessionToken <token>]

Or configure a named profile with the AWS CLI (recommended if you have AWS CLI installed):
  aws configure --profile cost-tracker

After setting credentials, run Terraform commands:
  terraform init
  terraform plan -var-file=terraform.tfvars
  terraform apply -var-file=terraform.tfvars

Note: This script only sets environment variables for the running PowerShell session.
Close the shell to clear them, or re-run with blank values to unset.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$AccessKey,

    [Parameter(Mandatory=$false)]
    [string]$SecretKey,

    [Parameter(Mandatory=$false)]
    [string]$SessionToken
)

function Set-AwsEnvVars {
    param($ak, $sk, $token)

    if ($ak) {
        $env:AWS_ACCESS_KEY_ID = $ak
        Write-Host "Set AWS_ACCESS_KEY_ID"
    } else {
        Remove-Item Env:\AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
        Write-Host "Cleared AWS_ACCESS_KEY_ID"
    }

    if ($sk) {
        $env:AWS_SECRET_ACCESS_KEY = $sk
        Write-Host "Set AWS_SECRET_ACCESS_KEY"
    } else {
        Remove-Item Env:\AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
        Write-Host "Cleared AWS_SECRET_ACCESS_KEY"
    }

    if ($token) {
        $env:AWS_SESSION_TOKEN = $token
        Write-Host "Set AWS_SESSION_TOKEN"
    } else {
        Remove-Item Env:\AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
        Write-Host "Cleared AWS_SESSION_TOKEN"
    }
}

Set-AwsEnvVars -ak $AccessKey -sk $SecretKey -token $SessionToken

Write-Host "\nCredentials in this PowerShell session are set. Run 'terraform init' then 'terraform plan'/'apply'." -ForegroundColor Green
