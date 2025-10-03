# 🚀 AWS Cost Tracker - Deployment Guide

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Post-Deployment](#post-deployment)

## 🔧 Prerequisites

### Required Software
- **AWS CLI** (v2.0+)
- **Terraform** (v1.0+)
- **Git** (v2.0+)
- **Node.js** (v16+) - for local development
- **Python** (v3.9+) - for Lambda functions

### AWS Account Requirements
- **AWS Account** with billing enabled
- **Administrator Access** or equivalent permissions
- **Cost Explorer API** enabled
- **Billing alerts** enabled

### Required AWS Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:*",
        "apigateway:*",
        "dynamodb:*",
        "s3:*",
        "cloudwatch:*",
        "sns:*",
        "events:*",
        "iam:*",
        "ce:*",
        "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## ⚡ Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd cloud-cost-tracker
```

### 2. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 4. Access Dashboard
```bash
# Get dashboard URL from terraform output
terraform output dashboard_url
```

## 📝 Detailed Setup

### Step 1: Environment Preparation

#### Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your default output format (json)
```

#### Verify AWS Access
```bash
aws sts get-caller-identity
# Should return your AWS account details
```

#### Enable Required Services
```bash
# Enable Cost Explorer API
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-02 --granularity MONTHLY --metrics BlendedCost

# Enable Billing Alerts
aws cloudwatch put-metric-alarm --alarm-name test-billing-alarm --alarm-description "Test billing alarm" --metric-name EstimatedCharges --namespace AWS/Billing --statistic Maximum --period 86400 --threshold 100 --comparison-operator GreaterThanThreshold
```

### Step 2: Terraform Configuration

#### Initialize Terraform
```bash
terraform init
```

#### Review Configuration
```bash
terraform plan
```

#### Deploy Infrastructure
```bash
terraform apply
```

**Expected Output:**
```
Plan: 25 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

### Step 3: Verify Deployment

#### Check Terraform Outputs
```bash
terraform output
```

**Expected Outputs:**
```
api_gateway_url = "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev"
dashboard_url = "https://dat5ebqhkbl9j.cloudfront.net"
dynamodb_table_name = "cost-tracker-cost-logs"
sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:cost-tracker-cost-alerts"
```

#### Test API Endpoints
```bash
# Test dashboard data endpoint
curl "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/dashboard-data?region=us-east-1"

# Expected response: JSON with cost data
```

#### Access Dashboard
```bash
# Open dashboard in browser
open https://dat5ebqhkbl9j.cloudfront.net
```

## ⚙️ Configuration

### terraform.tfvars Configuration

```hcl
# Basic Configuration
aws_region         = "us-east-1"
project_name       = "cost-tracker"
environment        = "dev"

# Cost Monitoring
cost_threshold     = 0.03
notification_email = "your-email@example.com"
schedule_expression = "rate(6 hours)"

# Optional: Custom Domain
# custom_domain     = "cost-tracker.yourdomain.com"
# certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

### Environment Variables

#### Lambda Environment Variables
```yaml
# API Handler Lambda
DYNAMODB_TABLE_NAME: cost-tracker-cost-logs
SNS_TOPIC_ARN: arn:aws:sns:us-east-1:123456789012:cost-tracker-cost-alerts
CLOUDWATCH_ALARM_NAME: cost-tracker-billing-alarm

# Cost Logger Lambda
DYNAMODB_TABLE_NAME: cost-tracker-cost-logs
SNS_TOPIC_ARN: arn:aws:sns:us-east-1:123456789012:cost-tracker-cost-alerts
```

### IAM Permissions

#### Lambda Execution Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:PutItem",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:PutMetricAlarm",
        "ce:GetCostAndUsage",
        "ce:GetCostForecast",
        "sns:Publish",
        "ec2:DescribeInstances",
        "ec2:StopInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

## ✅ Verification

### 1. Infrastructure Verification

#### Check Lambda Functions
```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cost-tracker`)]'
```

#### Check DynamoDB Table
```bash
aws dynamodb describe-table --table-name cost-tracker-cost-logs
```

#### Check API Gateway
```bash
aws apigateway get-rest-apis --query 'items[?name==`cost-tracker-api`]'
```

#### Check S3 Bucket
```bash
aws s3 ls s3://cost-tracker-dashboard-$(terraform output -raw bucket_suffix)
```

### 2. Functionality Verification

#### Test Cost Data Retrieval
```bash
# Test API endpoint
curl -X GET "https://$(terraform output -raw api_gateway_url)/dashboard-data?region=us-east-1"

# Expected: JSON response with cost data
```

#### Test Threshold Update
```bash
# Test threshold update
curl -X POST "https://$(terraform output -raw api_gateway_url)/update-threshold" \
  -H "Content-Type: application/json" \
  -d '{"threshold": 10.00, "region": "us-east-1"}'

# Expected: Success response
```

#### Test Emergency Stop
```bash
# Test emergency stop (if you have EC2 instances)
curl -X POST "https://$(terraform output -raw api_gateway_url)/stop-ec2" \
  -H "Content-Type: application/json" \
  -d '{"region": "us-east-1"}'

# Expected: Response with stopped instances
```

### 3. Dashboard Verification

#### Check Dashboard Loading
1. Open dashboard URL in browser
2. Verify all KPI cards load
3. Check that cost data displays
4. Test dark/light mode toggle
5. Verify settings panel works

#### Check Real-time Updates
1. Wait for auto-refresh (30 seconds)
2. Verify data updates
3. Check log entries appear
4. Test manual refresh button

## 🔧 Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

**Error**: `Error: Error creating Lambda function`
**Solution**:
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check IAM permissions
aws iam get-user

# Retry with more verbose output
terraform apply -auto-approve -var="debug=true"
```

#### 2. API Gateway Returns 403

**Error**: `{"message": "Forbidden"}`
**Solution**:
```bash
# Force API Gateway redeployment
terraform apply -auto-approve

# Or manually redeploy
aws apigateway create-deployment --rest-api-id $(terraform output -raw api_gateway_id) --stage-name dev
```

#### 3. Dashboard Shows $0.00

**Error**: Cost data not displaying
**Solution**:
```bash
# Check Lambda logs
aws logs filter-log-events --log-group-name "/aws/lambda/cost-tracker-api-handler" --start-time $(date -d '1 hour ago' +%s)000

# Check CloudWatch billing metrics
aws cloudwatch get-metric-statistics --namespace AWS/Billing --metric-name EstimatedCharges --start-time $(date -d '1 day ago' --iso-8601) --end-time $(date --iso-8601) --period 86400 --statistics Maximum
```

#### 4. Email Notifications Not Working

**Error**: No email alerts received
**Solution**:
```bash
# Check SNS topic
aws sns list-topics

# Check subscriptions
aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)

# Test SNS manually
aws sns publish --topic-arn $(terraform output -raw sns_topic_arn) --message "Test message" --subject "Test"
```

#### 5. CloudFront Not Updating

**Error**: Changes not visible in dashboard
**Solution**:
```bash
# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --paths "/*"

# Check invalidation status
aws cloudfront get-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --id $(aws cloudfront list-invalidations --distribution-id $(terraform output -raw cloudfront_distribution_id) --query 'InvalidationList.Items[0].Id' --output text)
```

### Debug Commands

#### Check System Health
```bash
# Check all resources
terraform show

# Check Lambda function status
aws lambda get-function --function-name cost-tracker-api-handler

# Check DynamoDB table status
aws dynamodb describe-table --table-name cost-tracker-cost-logs --query 'Table.TableStatus'

# Check CloudWatch alarms
aws cloudwatch describe-alarms --alarm-names cost-tracker-billing-alarm
```

#### Check Logs
```bash
# API Handler logs
aws logs filter-log-events --log-group-name "/aws/lambda/cost-tracker-api-handler" --start-time $(date -d '1 hour ago' +%s)000

# Cost Logger logs
aws logs filter-log-events --log-group-name "/aws/lambda/cost-tracker-cost-logger" --start-time $(date -d '1 hour ago' +%s)000
```

## 🎯 Post-Deployment

### 1. Initial Configuration

#### Set Up Email Notifications
1. Check email for SNS subscription confirmation
2. Click confirmation link
3. Verify subscription status in AWS Console

#### Configure Initial Threshold
1. Open dashboard
2. Click "⚙️ Settings"
3. Set appropriate threshold (e.g., $50.00)
4. Click "Update Threshold"

#### Test Emergency Stop
1. Launch a test EC2 instance
2. Click "🚨 Emergency Stop"
3. Confirm action
4. Verify instance stopped

### 2. Monitoring Setup

#### CloudWatch Dashboards
```bash
# Create custom dashboard
aws cloudwatch put-dashboard --dashboard-name "CostTracker" --dashboard-body '{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Lambda", "Invocations", "FunctionName", "cost-tracker-api-handler"],
          ["AWS/Lambda", "Errors", "FunctionName", "cost-tracker-api-handler"]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "Lambda Metrics"
      }
    }
  ]
}'
```

#### Cost Monitoring
1. Set up AWS Budgets for monthly spending
2. Configure additional CloudWatch alarms
3. Set up Cost Anomaly Detection

### 3. Security Hardening

#### IAM Best Practices
```bash
# Create least-privilege IAM user for dashboard access
aws iam create-user --user-name cost-tracker-user

# Attach minimal policy
aws iam attach-user-policy --user-name cost-tracker-user --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```

#### Network Security
```bash
# Enable VPC Flow Logs (if using VPC)
aws ec2 create-flow-logs --resource-type VPC --resource-ids vpc-12345678 --traffic-type ALL --log-destination-type cloud-watch-logs --log-group-name VPCFlowLogs
```

### 4. Backup and Recovery

#### Backup Strategy
```bash
# Backup Terraform state
aws s3 cp terraform.tfstate s3://your-backup-bucket/terraform-state-backup-$(date +%Y%m%d).tfstate

# Backup DynamoDB table
aws dynamodb create-backup --table-name cost-tracker-cost-logs --backup-name cost-tracker-backup-$(date +%Y%m%d)
```

#### Recovery Procedures
```bash
# Restore from backup
aws s3 cp s3://your-backup-bucket/terraform-state-backup-20241002.tfstate terraform.tfstate

# Restore DynamoDB table
aws dynamodb restore-table-from-backup --target-table-name cost-tracker-cost-logs-restored --backup-arn arn:aws:dynamodb:us-east-1:123456789012:table/cost-tracker-cost-logs/backup/1234567890123-12345678
```

## 📊 Performance Optimization

### Lambda Optimization
```bash
# Update Lambda memory allocation
aws lambda update-function-configuration --function-name cost-tracker-api-handler --memory-size 512

# Enable provisioned concurrency (if needed)
aws lambda put-provisioned-concurrency-config --function-name cost-tracker-api-handler --provisioned-concurrency-config AllocatedConcurrency=10
```

### DynamoDB Optimization
```bash
# Enable point-in-time recovery
aws dynamodb update-continuous-backups --table-name cost-tracker-cost-logs --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

### CloudFront Optimization
```bash
# Update cache behavior
aws cloudfront update-distribution --id $(terraform output -raw cloudfront_distribution_id) --distribution-config file://cloudfront-config.json
```

## 🎉 Success Criteria

Your deployment is successful when:

- ✅ **Dashboard loads** without errors
- ✅ **Cost data displays** correctly ($1.07 or actual amount)
- ✅ **API endpoints respond** with valid JSON
- ✅ **Email notifications work** for threshold breaches
- ✅ **Emergency stop functions** properly
- ✅ **Logs are generated** every 6 hours
- ✅ **Settings panel updates** thresholds
- ✅ **Multi-region switching** works
- ✅ **Dark/light mode** toggles properly
- ✅ **Mobile responsiveness** works on all devices

## 📞 Support

If you encounter issues:

1. **Check the troubleshooting section** above
2. **Review CloudWatch logs** for error details
3. **Verify AWS permissions** and service limits
4. **Check the GitHub issues** for known problems
5. **Contact support** with detailed error information

---

**🎯 Your AWS Cost Tracker is now ready for production use!**





