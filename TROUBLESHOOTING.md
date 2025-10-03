# 🔧 AWS Cost Tracker - Troubleshooting Guide

## 📋 Table of Contents

- [Common Issues](#common-issues)
- [Dashboard Issues](#dashboard-issues)
- [API Issues](#api-issues)
- [Cost Data Issues](#cost-data-issues)
- [Email Notification Issues](#email-notification-issues)
- [Performance Issues](#performance-issues)
- [Deployment Issues](#deployment-issues)
- [Debug Commands](#debug-commands)
- [Prevention Tips](#prevention-tips)

## 🚨 Common Issues

### 1. Dashboard Shows $0.00 Instead of Real Costs

**Symptoms:**
- Dashboard displays $0.00 for current month spend
- "📈 Based on X alerts" instead of "📊 Real AWS Data"
- No cost data in KPI cards

**Root Causes:**
1. **Cost Explorer API delay** (24-48 hours)
2. **CloudWatch billing metrics not available**
3. **IAM permissions insufficient**
4. **Very small costs** being rounded to $0.00

**Solutions:**

#### Check Cost Data Sources
```bash
# Check CloudWatch billing metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Billing \
  --metric-name EstimatedCharges \
  --start-time $(date -d '1 day ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 86400 \
  --statistics Maximum

# Check Cost Explorer API
aws ce get-cost-and-usage \
  --time-period Start=2024-10-01,End=2024-10-02 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

#### Verify IAM Permissions
```bash
# Check Lambda execution role
aws iam get-role --role-name cost-tracker-lambda-role

# Check attached policies
aws iam list-attached-role-policies --role-name cost-tracker-lambda-role
```

#### Fix Small Amount Rounding
The system now handles micro-amounts properly. If you still see $0.00:
1. Wait 24-48 hours for Cost Explorer data
2. Check if your AWS account has minimal usage
3. Verify billing alerts are enabled

### 2. API Gateway Returns 403 Forbidden

**Symptoms:**
- API calls return 403 status
- "Access denied" error messages
- Dashboard fails to load data

**Root Causes:**
1. **API Gateway deployment stale**
2. **Lambda permissions incorrect**
3. **CORS configuration issues**

**Solutions:**

#### Force API Gateway Redeployment
```bash
# Redeploy API Gateway
terraform apply -auto-approve

# Or manually redeploy
aws apigateway create-deployment \
  --rest-api-id $(terraform output -raw api_gateway_id) \
  --stage-name dev
```

#### Check Lambda Permissions
```bash
# Verify API Gateway can invoke Lambda
aws lambda get-policy --function-name cost-tracker-api-handler

# Check Lambda execution role
aws iam get-role --role-name cost-tracker-lambda-role
```

### 3. Email Notifications Not Working

**Symptoms:**
- No email alerts received
- Threshold exceeded but no notification
- SNS subscription not confirmed

**Root Causes:**
1. **Email not verified in SNS**
2. **SNS topic not configured**
3. **CloudWatch alarm not triggering**

**Solutions:**

#### Check SNS Configuration
```bash
# List SNS topics
aws sns list-topics

# Check subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# Test SNS manually
aws sns publish \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --message "Test message" \
  --subject "Test"
```

#### Verify Email Subscription
1. Check your email for SNS confirmation
2. Click the confirmation link
3. Verify subscription status in AWS Console

#### Check CloudWatch Alarm
```bash
# Check alarm status
aws cloudwatch describe-alarms \
  --alarm-names cost-tracker-billing-alarm

# Check alarm history
aws cloudwatch describe-alarm-history \
  --alarm-name cost-tracker-billing-alarm \
  --start-date $(date -d '1 day ago' --iso-8601)
```

## 🖥️ Dashboard Issues

### 1. Dashboard Not Loading

**Symptoms:**
- Blank page or loading spinner
- JavaScript errors in console
- CloudFront 403/404 errors

**Solutions:**

#### Check CloudFront Status
```bash
# Check distribution status
aws cloudfront get-distribution \
  --id $(terraform output -raw cloudfront_distribution_id)

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

#### Check S3 Bucket
```bash
# List S3 objects
aws s3 ls s3://$(terraform output -raw s3_bucket_name)

# Check bucket policy
aws s3api get-bucket-policy \
  --bucket $(terraform output -raw s3_bucket_name)
```

#### Verify Frontend Files
```bash
# Check if files exist
aws s3 ls s3://$(terraform output -raw s3_bucket_name)/

# Download and check content
aws s3 cp s3://$(terraform output -raw s3_bucket_name)/index.html ./index.html
```

### 2. Dashboard Shows Old Data

**Symptoms:**
- Data not updating after changes
- Stale cost information
- Settings not persisting

**Solutions:**

#### Clear Browser Cache
1. Hard refresh (Ctrl+F5 or Cmd+Shift+R)
2. Clear browser cache
3. Try incognito/private mode

#### Invalidate CloudFront
```bash
# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"

# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --id $(aws cloudfront list-invalidations \
    --distribution-id $(terraform output -raw cloudfront_distribution_id) \
    --query 'InvalidationList.Items[0].Id' --output text)
```

### 3. Settings Panel Not Working

**Symptoms:**
- Threshold updates fail
- Settings don't save
- Error messages in console

**Solutions:**

#### Check API Endpoint
```bash
# Test threshold update API
curl -X POST "$(terraform output -raw api_gateway_url)/update-threshold" \
  -H "Content-Type: application/json" \
  -d '{"threshold": 10.00, "region": "us-east-1"}'
```

#### Check Lambda Logs
```bash
# Check API handler logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/cost-tracker-api-handler" \
  --start-time $(date -d '1 hour ago' +%s)000
```

## 🔌 API Issues

### 1. API Endpoints Not Responding

**Symptoms:**
- API calls timeout
- 500 Internal Server Error
- Lambda function errors

**Solutions:**

#### Check Lambda Function Status
```bash
# Check function status
aws lambda get-function --function-name cost-tracker-api-handler

# Check function configuration
aws lambda get-function-configuration --function-name cost-tracker-api-handler
```

#### Check Lambda Logs
```bash
# Get recent logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/cost-tracker-api-handler" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --query 'events[*].message' --output text
```

#### Test Lambda Directly
```bash
# Invoke Lambda directly
aws lambda invoke \
  --function-name cost-tracker-api-handler \
  --payload '{"httpMethod":"GET","path":"/dashboard-data","queryStringParameters":{"region":"us-east-1"}}' \
  response.json

# Check response
cat response.json
```

### 2. CORS Issues

**Symptoms:**
- Browser CORS errors
- API calls blocked by browser
- "Access-Control-Allow-Origin" errors

**Solutions:**

#### Check API Gateway CORS
```bash
# Check CORS configuration
aws apigateway get-method \
  --rest-api-id $(terraform output -raw api_gateway_id) \
  --resource-id $(aws apigateway get-resources \
    --rest-api-id $(terraform output -raw api_gateway_id) \
    --query 'items[?pathPart==`dashboard-data`].id' --output text) \
  --http-method GET
```

#### Test with cURL
```bash
# Test with cURL (bypasses CORS)
curl -H "Origin: https://dat5ebqhkbl9j.cloudfront.net" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: X-Requested-With" \
  -X OPTIONS \
  "$(terraform output -raw api_gateway_url)/dashboard-data"
```

## 💰 Cost Data Issues

### 1. No Cost Data Available

**Symptoms:**
- "No cost data available" messages
- Empty service breakdown
- Forecast shows $0.00

**Solutions:**

#### Check AWS Billing
1. Verify billing is enabled in AWS Console
2. Check if you have any AWS usage
3. Ensure Cost Explorer is enabled

#### Check Cost Explorer API
```bash
# Test Cost Explorer API
aws ce get-cost-and-usage \
  --time-period Start=2024-10-01,End=2024-10-02 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

#### Check CloudWatch Billing
```bash
# Check billing metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Billing \
  --metric-name EstimatedCharges \
  --start-time $(date -d '7 days ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 86400 \
  --statistics Maximum
```

### 2. Incorrect Cost Data

**Symptoms:**
- Costs don't match AWS Console
- Outdated information
- Wrong service breakdown

**Solutions:**

#### Check Data Freshness
```bash
# Check when data was last updated
aws logs filter-log-events \
  --log-group-name "/aws/lambda/cost-tracker-api-handler" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern "Real cost data retrieved"
```

#### Compare with AWS Console
1. Check AWS Billing Dashboard
2. Compare Cost Explorer data
3. Verify date ranges match

## 📧 Email Notification Issues

### 1. No Email Alerts

**Symptoms:**
- Threshold exceeded but no email
- SNS notifications not working
- Email subscription not confirmed

**Solutions:**

#### Check Email Subscription
```bash
# List SNS subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# Check subscription status
aws sns get-subscription-attributes \
  --subscription-arn $(aws sns list-subscriptions-by-topic \
    --topic-arn $(terraform output -raw sns_topic_arn) \
    --query 'Subscriptions[0].SubscriptionArn' --output text)
```

#### Test Email Manually
```bash
# Send test email
aws sns publish \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --message "Test alert from AWS Cost Tracker" \
  --subject "Test Alert"
```

#### Check CloudWatch Alarm
```bash
# Check alarm state
aws cloudwatch describe-alarms \
  --alarm-names cost-tracker-billing-alarm \
  --query 'MetricAlarms[0].StateValue' --output text
```

### 2. Email Format Issues

**Symptoms:**
- Emails received but poorly formatted
- Missing information in alerts
- HTML rendering issues

**Solutions:**

#### Check SNS Message Format
```bash
# Check recent SNS messages
aws logs filter-log-events \
  --log-group-name "/aws/lambda/cost-tracker-cost-logger" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --filter-pattern "SNS"
```

## ⚡ Performance Issues

### 1. Slow Dashboard Loading

**Symptoms:**
- Dashboard takes long to load
- API calls timeout
- Poor user experience

**Solutions:**

#### Check Lambda Performance
```bash
# Check Lambda duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=cost-tracker-api-handler \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average,Maximum
```

#### Check API Gateway Latency
```bash
# Check API Gateway latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Latency \
  --dimensions Name=ApiName,Value=cost-tracker-api \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average,Maximum
```

#### Optimize Lambda Memory
```bash
# Update Lambda memory
aws lambda update-function-configuration \
  --function-name cost-tracker-api-handler \
  --memory-size 512
```

### 2. High Costs

**Symptoms:**
- Unexpected AWS charges
- High Lambda costs
- DynamoDB costs increasing

**Solutions:**

#### Check Lambda Costs
```bash
# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=cost-tracker-api-handler \
  --start-time $(date -d '1 day ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 3600 \
  --statistics Sum
```

#### Check DynamoDB Usage
```bash
# Check DynamoDB read/write capacity
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=cost-tracker-cost-logs \
  --start-time $(date -d '1 day ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 3600 \
  --statistics Sum
```

## 🚀 Deployment Issues

### 1. Terraform Apply Fails

**Symptoms:**
- Terraform apply errors
- Resource creation failures
- State lock issues

**Solutions:**

#### Check AWS Credentials
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check AWS region
aws configure get region
```

#### Check Resource Limits
```bash
# Check Lambda limits
aws lambda get-account-settings

# Check API Gateway limits
aws apigateway get-usage \
  --usage-plan-id $(aws apigateway get-usage-plans \
    --query 'items[0].id' --output text)
```

#### Resolve State Lock
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or wait for lock to expire
# Locks typically expire after 20 minutes
```

### 2. Lambda Deployment Fails

**Symptoms:**
- Lambda function not updating
- Code changes not reflected
- Deployment errors

**Solutions:**

#### Check Lambda Package
```bash
# Check package size
ls -la lambda/api_handler.zip

# Recreate package
cd lambda
zip -r api_handler.zip api_handler.py
```

#### Update Lambda Manually
```bash
# Update function code
aws lambda update-function-code \
  --function-name cost-tracker-api-handler \
  --zip-file fileb://lambda/api_handler.zip
```

## 🔍 Debug Commands

### System Health Check
```bash
#!/bin/bash
# Complete system health check

echo "=== AWS Cost Tracker Health Check ==="

# Check Lambda functions
echo "1. Lambda Functions:"
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cost-tracker`)].[FunctionName,Runtime,LastModified]' --output table

# Check DynamoDB table
echo "2. DynamoDB Table:"
aws dynamodb describe-table --table-name cost-tracker-cost-logs --query 'Table.[TableName,TableStatus,ItemCount]' --output table

# Check API Gateway
echo "3. API Gateway:"
aws apigateway get-rest-apis --query 'items[?name==`cost-tracker-api`].[name,createdDate]' --output table

# Check CloudWatch alarms
echo "4. CloudWatch Alarms:"
aws cloudwatch describe-alarms --alarm-names cost-tracker-billing-alarm --query 'MetricAlarms[0].[AlarmName,StateValue,StateUpdatedTimestamp]' --output table

# Check SNS topic
echo "5. SNS Topic:"
aws sns list-topics --query 'Topics[?contains(TopicArn, `cost-tracker`)].[TopicArn]' --output table

# Check recent logs
echo "6. Recent API Handler Logs:"
aws logs filter-log-events \
  --log-group-name "/aws/lambda/cost-tracker-api-handler" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --query 'events[-5:].[timestamp,message]' --output table

echo "=== Health Check Complete ==="
```

### Cost Data Debug
```bash
#!/bin/bash
# Debug cost data issues

echo "=== Cost Data Debug ==="

# Check CloudWatch billing
echo "1. CloudWatch Billing Metrics:"
aws cloudwatch get-metric-statistics \
  --namespace AWS/Billing \
  --metric-name EstimatedCharges \
  --start-time $(date -d '1 day ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 86400 \
  --statistics Maximum \
  --query 'Datapoints[0].Maximum' --output text

# Check Cost Explorer
echo "2. Cost Explorer Data:"
aws ce get-cost-and-usage \
  --time-period Start=2024-10-01,End=2024-10-02 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' --output text

# Test API endpoint
echo "3. API Endpoint Test:"
curl -s "$(terraform output -raw api_gateway_url)/dashboard-data?region=us-east-1" | jq '.realCostData.currentSpend'

echo "=== Debug Complete ==="
```

## 🛡️ Prevention Tips

### 1. Regular Monitoring
- Set up CloudWatch dashboards
- Monitor Lambda error rates
- Check DynamoDB throttling
- Review API Gateway metrics

### 2. Cost Optimization
- Right-size Lambda memory
- Use DynamoDB on-demand billing
- Monitor API Gateway usage
- Set up billing alerts

### 3. Security Best Practices
- Regular IAM permission reviews
- Enable CloudTrail logging
- Use least-privilege access
- Monitor for unusual activity

### 4. Backup and Recovery
- Regular Terraform state backups
- DynamoDB point-in-time recovery
- S3 versioning enabled
- CloudWatch logs retention

---

## 📞 Getting Help

If you're still experiencing issues:

1. **Check this troubleshooting guide** for your specific issue
2. **Run the debug commands** to gather information
3. **Review CloudWatch logs** for detailed error messages
4. **Check AWS Service Health** for service outages
5. **Contact support** with specific error details and logs

**Remember**: Most issues can be resolved by checking logs and verifying AWS service status!





