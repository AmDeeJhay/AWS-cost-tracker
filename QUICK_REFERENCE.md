# 🚀 Quick Reference - Cloud Cost Tracker

## 📥 Installation Commands

### Install Terraform
1. Download from: https://www.terraform.io/downloads
2. Extract `terraform.exe` to `C:\terraform`
3. Add `C:\terraform` to Windows PATH

### Install AWS CLI
1. Download from: https://aws.amazon.com/cli/
2. Run installer with default settings

### Install Git (Optional)
1. Download from: https://git-scm.com/download/win
2. Run installer with default settings

## ⚙️ Configuration Commands

### Configure AWS CLI
```powershell
aws configure
```
Enter your Access Key ID, Secret Key, region (us-east-1), and output format (json)

### Test AWS Connection
```powershell
aws sts get-caller-identity
```

### Create Terraform Variables
```powershell
copy terraform.tfvars.example terraform.tfvars
```
Then edit `terraform.tfvars` with your email address

## 🚀 Deployment Commands

### Initialize Terraform
```powershell
terraform init
```

### Review Deployment Plan
```powershell
terraform plan
```

### Deploy Infrastructure
```powershell
terraform apply
```
Type `yes` when prompted

### Get Important URLs
```powershell
terraform output
```

### Update Frontend and Re-deploy
```powershell
terraform apply
```

## 🧪 Testing Commands

### Test API Endpoint
```powershell
curl [YOUR_API_GATEWAY_URL]
```

### Check DynamoDB
```powershell
aws dynamodb scan --table-name cost-tracker-cost-logs
```

### List Lambda Functions
```powershell
aws lambda list-functions
```

### Check S3 Buckets
```powershell
aws s3 ls
```

## 🔧 Troubleshooting Commands

### Check Terraform Version
```powershell
terraform version
```

### Check AWS CLI Version
```powershell
aws --version
```

### Check AWS Credentials
```powershell
aws sts get-caller-identity
```

### View Terraform State
```powershell
terraform show
```

### Destroy Infrastructure (if needed)
```powershell
terraform destroy
```

## 📋 Prerequisites Checklist

- [ ] AWS Account created
- [ ] Cost Explorer enabled in AWS Console
- [ ] IAM user created with required permissions
- [ ] Terraform installed and in PATH
- [ ] AWS CLI installed and configured
- [ ] terraform.tfvars created with your email
- [ ] Terraform initialized (`terraform init`)

## 🎯 Required AWS Permissions

Your IAM user needs these policies:
- AmazonDynamoDBFullAccess
- AmazonS3FullAccess
- AmazonSNSFullAccess
- AmazonCloudWatchFullAccess
- AWSLambdaFullAccess
- AmazonAPIGatewayAdministrator
- AmazonEventBridgeFullAccess
- CloudFrontFullAccess
- AWSCostExplorerServiceFullAccess

## 📊 Expected Outputs

After successful deployment:
- **Dashboard URL**: CloudFront URL for the web interface
- **API URL**: API Gateway endpoint for data access
- **DynamoDB Table**: `cost-tracker-cost-logs`
- **SNS Topic**: `cost-tracker-cost-alerts`

## 🚨 Common Issues

**"Access Denied"**: Check AWS credentials and IAM permissions
**"Cost Explorer not enabled"**: Enable in AWS Console → Billing
**"Terraform not found"**: Check PATH environment variable
**"API Gateway 502"**: Check Lambda function logs in CloudWatch

## 💡 Pro Tips

1. **Test with low threshold**: Set `cost_threshold = 0.01` for quick testing
2. **Check CloudWatch logs**: Monitor Lambda function execution
3. **Confirm SNS subscription**: Check your email for confirmation link
4. **Use AWS Console**: Visual interface for debugging
5. **Keep credentials secure**: Never commit AWS keys to version control

## 📞 Need Help?

1. Check the detailed SETUP_GUIDE.md
2. Review AWS CloudWatch logs
3. Verify all prerequisites are installed
4. Check AWS service limits and permissions

---

**Happy Cost Tracking! 📊💰**
