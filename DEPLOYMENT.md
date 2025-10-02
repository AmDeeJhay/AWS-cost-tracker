# 🚀 Deployment Guide

## Quick Deployment Steps

### 1. Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Python 3.9+ (for Lambda functions)

### 2. Configure Variables
```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required configuration:**
```hcl
aws_region         = "us-east-1"
project_name       = "cost-tracker"
cost_threshold     = 10.00
notification_email = "your-email@example.com"  # REQUIRED
schedule_expression = "rate(6 hours)"
environment        = "dev"
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 4. Update Frontend with API URL
After deployment, Terraform will output the API Gateway URL. You need to update the frontend:

1. **Get the API URL from Terraform output:**
   ```bash
   terraform output api_gateway_url
   ```

2. **Update the frontend file:**
   - Open `frontend/index.html`
   - Find `YOUR_API_GATEWAY_URL` and replace with the actual URL
   - Save the file

3. **Re-apply to update S3:**
   ```bash
   terraform apply
   ```

### 5. Access Your Dashboard
```bash
# Get the dashboard URL
terraform output dashboard_url
```

Visit the URL in your browser to see your cost tracking dashboard!

## 🧪 Testing Your Deployment

### Test Lambda Functions
1. Go to AWS Lambda Console
2. Find the `cost-tracker-cost-logger` function
3. Click "Test" and create a test event
4. Check DynamoDB for new entries

### Test Alerts
1. Set a very low threshold in `terraform.tfvars`:
   ```hcl
   cost_threshold = 0.01
   ```
2. Run `terraform apply`
3. The alarm should trigger quickly

### Test Dashboard
1. Visit the CloudFront URL
2. Click "Refresh Data" button
3. Verify charts and data load correctly

## 📊 What You'll See

### Dashboard Features
- **Cost Trends Chart**: Interactive line chart showing cost over time
- **Statistics Cards**: Total monthly cost, data points, last update
- **Recent Activity**: Latest cost log entries
- **Detailed Table**: Complete cost logs with timestamps

### Backend Components
- **DynamoDB Table**: `cost-tracker-cost-logs` stores all cost data
- **Lambda Functions**: 
  - `cost-tracker-cost-logger`: Runs every 6 hours
  - `cost-tracker-api-handler`: Serves API requests
- **CloudWatch Alarm**: Monitors billing metrics
- **SNS Topic**: Sends email alerts when threshold exceeded

## 🔧 Customization

### Change Schedule
```hcl
# Every hour
schedule_expression = "rate(1 hour)"

# Daily at 9 AM UTC
schedule_expression = "cron(0 9 * * ? *)"

# Every 12 hours
schedule_expression = "rate(12 hours)"
```

### Modify Cost Threshold
```hcl
# For testing (triggers quickly)
cost_threshold = 0.01

# For production
cost_threshold = 100.00
```

### Add More Metrics
Edit `lambda/cost_logger.py` to fetch additional Cost Explorer metrics:
- Service-level costs
- Region-based costs
- Usage quantities
- Reserved instance utilization

## 🚨 Troubleshooting

### Common Issues

**Lambda function fails:**
- Check CloudWatch logs: `/aws/lambda/cost-tracker-cost-logger`
- Verify Cost Explorer API is enabled in your AWS account
- Check IAM permissions

**Dashboard shows "Error Loading Data":**
- Verify API Gateway URL is correct in `frontend/index.html`
- Check API Gateway logs in CloudWatch
- Ensure DynamoDB has data

**No email alerts:**
- Check SNS subscription is confirmed
- Verify email address is correct
- Check CloudWatch alarm state

### Debug Commands
```bash
# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/cost-tracker

# Test API endpoint
curl $(terraform output -raw api_gateway_url)

# Check DynamoDB
aws dynamodb scan --table-name cost-tracker-cost-logs

# Verify SNS topic
aws sns list-topics
```

## 💰 Cost Considerations

This system is designed to be cost-effective:
- **DynamoDB**: Pay-per-request (free tier: 25 GB storage, 25 RCU/WCU)
- **Lambda**: 1M free requests/month, 400,000 GB-seconds compute
- **CloudFront**: 1TB data transfer out, 10M requests/month
- **S3**: 5GB storage, 20,000 GET requests/month
- **EventBridge**: 1M events/month
- **API Gateway**: 1M API calls/month

**Estimated monthly cost for small usage: $0-5**

## 🛡️ Security Notes

- S3 bucket allows public read access for static content only
- API Gateway has no authentication (add API keys for production)
- Lambda functions have minimal required permissions
- All resources are tagged for organization

## 📈 Monitoring

Monitor your deployment:
- **CloudWatch Logs**: Lambda execution logs
- **CloudWatch Metrics**: API Gateway, DynamoDB, Lambda metrics
- **SNS Notifications**: Cost threshold alerts
- **DynamoDB**: Table size and performance metrics

## 🗑️ Cleanup

To remove all resources:
```bash
terraform destroy
```

**Warning**: This will delete all data in DynamoDB and S3 bucket!

---

## 🎉 Success!

You now have a complete Cloud Cost Tracker & Alert System running on AWS! The system will:

1. ✅ Monitor your AWS costs every 6 hours
2. ✅ Store cost data in DynamoDB
3. ✅ Send email alerts when thresholds are exceeded
4. ✅ Provide a beautiful web dashboard for cost visualization
5. ✅ Scale automatically with your usage

Happy cost tracking! 📊💰
