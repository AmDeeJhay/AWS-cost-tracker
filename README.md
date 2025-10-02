# Cloud Cost Tracker & Alert System

A comprehensive AWS cost monitoring and alerting system built entirely with Terraform Infrastructure as Code (IaC). This system monitors AWS billing metrics, stores cost data in DynamoDB, sends alerts when thresholds are exceeded, and provides a beautiful web dashboard for visualizing cost trends.

## 🏗️ Architecture Overview

This system provides end-to-end cost monitoring with the following components:

- **📊 DynamoDB Table**: Stores cost and usage logs with timestamp-based queries
- **🚨 CloudWatch Alarms**: Monitor estimated billing metrics and trigger alerts
- **📧 SNS Topic**: Send email/SMS notifications when thresholds are exceeded
- **⚡ Lambda Functions**: Scheduled cost logging and REST API endpoints
- **⏰ EventBridge Rule**: Triggers Lambda functions on configurable schedules
- **🌐 API Gateway**: Exposes cost data as RESTful API with CORS support
- **🌍 S3 + CloudFront**: Hosts static web dashboard with global CDN

## 📁 Project Structure

```
cloud-cost-tracker/
├── terraform/
│   ├── main.tf                 # Main Terraform configuration (minimal)
│   ├── provider.tf             # AWS provider and data sources
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── dynamodb.tf             # DynamoDB table configuration
│   ├── cloudwatch.tf           # CloudWatch alarms
│   ├── sns.tf                  # SNS topic and subscriptions
│   ├── iam.tf                  # IAM roles and policies
│   ├── lambda.tf               # Lambda functions
│   ├── eventbridge.tf          # EventBridge scheduling rules
│   ├── api_gateway.tf          # API Gateway configuration
│   ├── s3_cloudfront.tf        # S3 bucket and CloudFront distribution
│   └── terraform.tfvars.example # Example variables file
├── lambda/
│   ├── cost_logger.py          # Scheduled cost logging function
│   ├── api_handler.py          # API Gateway handler function
│   └── requirements.txt        # Python dependencies
├── frontend/
│   └── index.html              # Interactive web dashboard
├── architecture.md             # Detailed architecture documentation
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Python 3.9+ (for Lambda functions)

### 🔒 Security-First Setup

This project uses **minimal IAM permissions** following the principle of least privilege for better security.

**Choose your setup approach:**

1. **🔒 Secure Setup (Recommended)**: Uses minimal, scoped permissions
   - See `SECURE_SETUP_GUIDE.md` for detailed instructions
   - Uses custom IAM policy with only required permissions
   - Production-ready and secure

2. **⚡ Quick Setup**: Uses full access policies (for learning/testing)
   - See `SETUP_GUIDE.md` for basic instructions
   - Uses AWS managed policies with full access
   - Faster setup but less secure

### Deployment Steps

1. **Clone and navigate to the project:**
   ```bash
   git clone <repository-url>
   cd cloud-cost-tracker
   ```

2. **Choose your setup approach:**
   - **Secure**: Follow `SECURE_SETUP_GUIDE.md`
   - **Quick**: Follow `SETUP_GUIDE.md`

3. **Configure your variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

4. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Update the frontend with your API URL:**
   - After deployment, Terraform will output the API Gateway URL
   - Update `frontend/index.html` and replace `YOUR_API_GATEWAY_URL` with the actual URL
   - Re-run `terraform apply` to update the S3 object

## ⚙️ Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `notification_email` | Email for cost alerts | `admin@company.com` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-east-1` |
| `project_name` | Name prefix for resources | `cost-tracker` |
| `cost_threshold` | Cost threshold in USD | `10.00` |
| `schedule_expression` | EventBridge schedule | `rate(6 hours)` |
| `environment` | Environment name | `dev` |

## 🧪 Testing

Since billing metrics may not trigger naturally in test accounts:

### Manual Testing
1. **Test Lambda Functions:**
   - Go to AWS Lambda Console
   - Manually invoke the `cost-logger` function
   - Check DynamoDB for new entries

2. **Test Alerts:**
   - Set `cost_threshold = 0.01` in `terraform.tfvars`
   - Run `terraform apply`
   - The alarm should trigger quickly

3. **Test Dashboard:**
   - Visit the CloudFront URL from Terraform outputs
   - Verify data loads and charts render correctly

### Automated Testing
```bash
# Test API endpoint
curl https://your-api-gateway-url/cost-data

# Check DynamoDB entries
aws dynamodb scan --table-name cost-tracker-cost-logs
```

## 📊 Dashboard Features

The web dashboard includes:

- **📈 Interactive Charts**: Cost trends over time using Chart.js
- **📋 Data Tables**: Detailed cost logs with timestamps
- **📊 Statistics Cards**: Total costs, data points, last update
- **🔄 Real-time Updates**: Refresh button for latest data
- **📱 Responsive Design**: Works on desktop and mobile
- **🎨 Modern UI**: Beautiful gradient design with smooth animations

## 🔧 Customization

### Adding New Metrics
1. Modify `lambda/cost_logger.py` to fetch additional Cost Explorer metrics
2. Update the DynamoDB schema in `dynamodb.tf`
3. Enhance the frontend to display new data

### Changing Alert Thresholds
1. Update `cost_threshold` in `terraform.tfvars`
2. Run `terraform apply`
3. Test with a low threshold (e.g., $0.01)

### Modifying Schedule
1. Change `schedule_expression` in `terraform.tfvars`
2. Examples: `rate(1 hour)`, `cron(0 9 * * ? *)` (daily at 9 AM)

## 🛡️ Security Considerations

- **IAM Roles**: Least privilege access for all resources
- **S3 Bucket**: Public read access only for static content
- **API Gateway**: No authentication (can be enhanced with API keys)
- **Lambda**: Minimal required permissions
- **CloudWatch**: Secure monitoring and alerting

## 💰 Cost Optimization

- **DynamoDB**: Pay-per-request billing mode
- **Lambda**: Appropriate timeouts and memory allocation
- **CloudFront**: Caching to reduce origin requests
- **S3**: Standard storage class for static content
- **EventBridge**: Free tier usage for scheduling

## 🚨 Troubleshooting

### Common Issues

1. **Lambda function fails:**
   - Check CloudWatch logs
   - Verify IAM permissions
   - Ensure Cost Explorer API is enabled

2. **Dashboard not loading:**
   - Verify S3 bucket policy allows public read
   - Check CloudFront distribution status
   - Update API URL in frontend code

3. **Alerts not working:**
   - Confirm SNS subscription is confirmed
   - Check CloudWatch alarm state
   - Verify cost threshold is appropriate

### Debugging Commands

```bash
# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/cost-tracker

# Test API Gateway
aws apigateway get-rest-apis

# Verify DynamoDB
aws dynamodb describe-table --table-name cost-tracker-cost-logs
```

## 📈 Monitoring and Maintenance

- **CloudWatch Logs**: Monitor Lambda function execution
- **CloudWatch Metrics**: Track API Gateway and DynamoDB usage
- **SNS Notifications**: Receive alerts for cost threshold breaches
- **DynamoDB**: Monitor table size and performance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS CloudWatch logs
3. Open an issue in the repository
4. Check AWS documentation for service-specific issues

---

**Note**: This system is designed for cost monitoring and alerting. For production use, consider adding authentication, enhanced security measures, and additional monitoring capabilities.