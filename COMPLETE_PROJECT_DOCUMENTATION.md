# 📚 Complete Cloud Cost Tracker Project Documentation

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Data Flow](#architecture--data-flow)
3. [Terraform Infrastructure Files](#terraform-infrastructure-files)
4. [Lambda Functions](#lambda-functions)
5. [Frontend Dashboard](#frontend-dashboard)
6. [Setup & Configuration Files](#setup--configuration-files)
7. [Documentation Files](#documentation-files)
8. [Deployment Process](#deployment-process)
9. [Testing & Validation](#testing--validation)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## 🎯 Project Overview

The Cloud Cost Tracker is a comprehensive AWS cost monitoring and alerting system built entirely with Infrastructure as Code (IaC) using Terraform. It provides:

- **Real-time cost monitoring** with CloudWatch alarms
- **Automated email alerts** when spending exceeds thresholds
- **Historical cost logging** in DynamoDB
- **Interactive web dashboard** for data visualization
- **Scheduled monitoring** every 6 hours
- **REST API** for programmatic access

### 🏗️ Core Components
- **8 Terraform configuration files** defining AWS infrastructure
- **2 Lambda functions** for backend processing
- **1 HTML dashboard** for user interface
- **Multiple setup scripts** for easy deployment
- **Comprehensive documentation** for maintenance

---

## 🏛️ Architecture & Data Flow

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   EventBridge   │────│   SNS Topic     │────│ Lambda Logger   │
│   (Schedule)    │    │  (Messaging)    │    │ (Cost Logging)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                │                        ▼
┌─────────────────┐             │              ┌─────────────────┐
│   CloudWatch    │─────────────┘              │    DynamoDB     │
│   (Billing)     │                            │  (Data Store)   │
└─────────────────┘                            └─────────────────┘
        │                                               ▲
        ▼                                               │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Email       │    │  API Gateway    │────│ Lambda Handler  │
│ Notifications   │    │   (REST API)    │    │  (API Server)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌─────────────────┐
│   CloudFront    │────│   S3 Bucket     │
│     (CDN)       │    │  (Static Site)  │
└─────────────────┘    └─────────────────┘
        │
        ▼
┌─────────────────┐
│  Web Dashboard  │
│  (User Access)  │
└─────────────────┘
```

### Data Flow Patterns

#### 1. Cost Alert Flow
```
AWS Billing → CloudWatch Alarm → SNS Topic → Email + Lambda → DynamoDB
```

#### 2. Dashboard Access Flow
```
User → CloudFront → S3 (HTML) → API Gateway → Lambda → DynamoDB → Response
```

#### 3. Scheduled Monitoring Flow
```
EventBridge (Schedule) → SNS Topic → Lambda Function → DynamoDB
```

---

## 🏗️ Terraform Infrastructure Files

### 1. **`main.tf`** - Project Entry Point
```hcl
# This file is intentionally left minimal as resources are organized in separate files
```

**Purpose**: 
- Central reference point for the project
- All actual resources are defined in specialized files
- Maintains clean separation of concerns

**Best Practice**: Using separate files for different AWS services improves maintainability and readability.

---

### 2. **`provider.tf`** - AWS Provider Configuration

**Purpose**: Configures Terraform providers and data sources

**Key Components**:
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
```

**Configuration Details**:
- **Terraform Version**: Requires 1.0 or higher
- **AWS Provider**: Version 5.x for latest features
- **Archive Provider**: Used for creating Lambda deployment packages
- **Data Sources**: Get current AWS account ID and region

---

### 3. **`variables.tf`** - Input Variables

**Purpose**: Defines all configurable parameters for the system

**Variable Definitions**:
```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "cost-tracker"
}

variable "cost_threshold" {
  description = "Cost threshold in USD for alerts"
  type        = number
  default     = 10.00
}

variable "notification_email" {
  description = "Email address for cost alerts"
  type        = string
  # No default - must be provided
}

variable "schedule_expression" {
  description = "EventBridge schedule for cost logging (cron or rate)"
  type        = string
  default     = "rate(6 hours)"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
```

**Configuration Guide**:
- **Required Variables**: `notification_email` (must be provided)
- **Optional Variables**: All others have sensible defaults
- **Customization**: Modify defaults or override in `terraform.tfvars`

---

### 4. **`outputs.tf`** - System Information

**Purpose**: Displays important information after deployment

**Key Outputs**:
```hcl
# Database Information
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for cost logs"
  value       = aws_dynamodb_table.cost_logs.name
}

# API Information
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.cost_tracker_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

# Dashboard Information
output "dashboard_url" {
  description = "URL of the CloudFront dashboard"
  value       = "https://${aws_cloudfront_distribution.dashboard_distribution.domain_name}"
}

# Setup Instructions
output "deployment_instructions" {
  description = "Instructions for completing the deployment"
  value = <<-EOT
    Deployment completed! Here's what you need to do next:
    
    1. Update the frontend/index.html file:
       - Replace 'YOUR_API_GATEWAY_URL' with: ${aws_api_gateway_deployment.cost_tracker_deployment.invoke_url}
    
    2. Re-upload the frontend to S3:
       - Run: terraform apply (to update the S3 object)
    
    3. Test the system:
       - Visit the dashboard: https://${aws_cloudfront_distribution.dashboard_distribution.domain_name}
       - Manually invoke the cost logger Lambda function
       - Check DynamoDB for logged entries
  EOT
}
```

**Information Provided**:
- Resource names and ARNs
- Access URLs for dashboard and API
- Step-by-step post-deployment instructions
- Testing and validation guidance

---

### 5. **`dynamodb.tf`** - Data Storage Configuration

**Purpose**: Creates NoSQL database for storing cost logs

**Resource Definition**:
```hcl
resource "aws_dynamodb_table" "cost_logs" {
  name           = "${var.project_name}-cost-logs"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-cost-logs"
    Environment = var.environment
  }
}
```

**Configuration Details**:
- **Table Name**: `cost-tracker-cost-logs`
- **Billing Mode**: Pay-per-request (cost-effective for low usage)
- **Primary Key**: `id` (String) - stores ISO timestamp
- **Attributes**: Only primary key defined (DynamoDB is schemaless)
- **Capacity**: Auto-scaling based on demand

**Data Structure**:
```json
{
  "id": "2024-01-15T10:30:00.000Z",
  "message": "Cost threshold exceeded: $15.50"
}
```

---

### 6. **`cloudwatch.tf`** - Cost Monitoring Configuration

**Purpose**: Sets up automated billing monitoring and alerts

**Resource Definition**:
```hcl
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "${var.project_name}-billing-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = var.cost_threshold
  alarm_description   = "This metric monitors estimated billing charges"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name        = "${var.project_name}-billing-alarm"
    Environment = var.environment
  }
}
```

**Configuration Details**:
- **Metric**: AWS/Billing EstimatedCharges
- **Threshold**: Configurable via `cost_threshold` variable
- **Evaluation**: Checks once daily (86400 seconds)
- **Currency**: USD (can be modified for other currencies)
- **Action**: Sends alert to SNS topic when threshold exceeded

**Monitoring Behavior**:
- Checks estimated charges every 24 hours
- Triggers when current month's charges exceed threshold
- Sends notification to SNS topic (which triggers email and Lambda)

---

### 7. **`sns.tf`** - Notification System Configuration

**Purpose**: Creates messaging system for cost alerts

**Resource Definitions**:
```hcl
# SNS Topic for alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-cost-alerts"
  
  tags = {
    Name        = "${var.project_name}-cost-alerts"
    Environment = var.environment
  }
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email_notification" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
```

**Configuration Details**:
- **Topic Name**: `cost-tracker-cost-alerts`
- **Subscription Protocol**: Email
- **Endpoint**: User-configured email address
- **Confirmation**: Email confirmation required after deployment

**Message Flow**:
1. CloudWatch alarm triggers SNS topic
2. SNS sends email to configured address
3. SNS also triggers Lambda function for logging

---

### 8. **`iam.tf`** - Security and Permissions Configuration

**Purpose**: Defines security roles and policies with least privilege access

**Resource Definitions**:
```hcl
# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.cost_logs.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ce:GetDimensionValues",
          "ce:GetUsageAndCosts",
          "ce:GetCostAndUsage"
        ]
        Resource = "*"
      }
    ]
  })
}
```

**Security Features**:
- **Least Privilege**: Only grants minimum required permissions
- **Service-Specific**: Lambda can only assume this role
- **Resource-Specific**: DynamoDB permissions limited to cost_logs table
- **Logging**: Basic CloudWatch logging permissions
- **Cost Explorer**: Read-only access to billing data

**Permissions Granted**:
1. **CloudWatch Logs**: Create and write log entries
2. **DynamoDB**: Read/write access to cost_logs table only
3. **Cost Explorer**: Read billing and usage data

---

### 9. **`lambda.tf`** - Serverless Function Configuration

**Purpose**: Defines and deploys Lambda functions for backend processing

**Resource Definitions**:
```hcl
# Create Lambda deployment packages
data "archive_file" "cost_logger_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/cost_logger.py"
  output_path = "${path.module}/lambda/cost_logger.zip"
}

data "archive_file" "api_handler_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/api_handler.py"
  output_path = "${path.module}/lambda/api_handler.zip"
}

# Lambda function for cost logging
resource "aws_lambda_function" "cost_logger" {
  filename         = data.archive_file.cost_logger_zip.output_path
  function_name    = "${var.project_name}-cost-logger"
  role            = aws_iam_role.lambda_role.arn
  handler         = "cost_logger.lambda_handler"
  source_code_hash = data.archive_file.cost_logger_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.cost_logs.name
    }
  }

  tags = {
    Name        = "${var.project_name}-cost-logger"
    Environment = var.environment
  }
}

# Lambda function for API
resource "aws_lambda_function" "api_handler" {
  filename         = data.archive_file.api_handler_zip.output_path
  function_name    = "${var.project_name}-api-handler"
  role            = aws_iam_role.lambda_role.arn
  handler         = "api_handler.lambda_handler"
  source_code_hash = data.archive_file.api_handler_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.cost_logs.name
    }
  }

  tags = {
    Name        = "${var.project_name}-api-handler"
    Environment = var.environment
  }
}
```

**Function Specifications**:

#### Cost Logger Function
- **Purpose**: Processes SNS messages and logs cost alerts
- **Runtime**: Python 3.9
- **Timeout**: 60 seconds
- **Memory**: Default (128 MB)
- **Trigger**: SNS topic messages
- **Environment**: DynamoDB table name

#### API Handler Function
- **Purpose**: Serves cost data via REST API
- **Runtime**: Python 3.9
- **Timeout**: 30 seconds
- **Memory**: Default (128 MB)
- **Trigger**: API Gateway requests
- **Environment**: DynamoDB table name

**Deployment Process**:
1. Terraform packages Python files into ZIP archives
2. Calculates file hashes for change detection
3. Uploads to AWS Lambda service
4. Configures runtime environment and permissions

---

### 10. **`eventbridge.tf`** - Scheduling Configuration

**Purpose**: Sets up automated scheduling for cost monitoring

**Resource Definitions**:
```hcl
# EventBridge rule for scheduled SNS message
resource "aws_cloudwatch_event_rule" "cost_logger_schedule" {
  name                = "${var.project_name}-cost-logger-schedule"
  description         = "Trigger cost logger via SNS on schedule"
  schedule_expression = var.schedule_expression

  tags = {
    Name        = "${var.project_name}-cost-logger-schedule"
    Environment = var.environment
  }
}

# EventBridge target - SNS topic
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.cost_logger_schedule.name
  target_id = "SNSTarget"
  arn       = aws_sns_topic.cost_alerts.arn
}

# SNS topic policy for EventBridge
resource "aws_sns_topic_policy" "eventbridge_policy" {
  arn = aws_sns_topic.cost_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.cost_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# SNS subscription for Lambda
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cost_logger.arn
}

# Lambda permission for SNS
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_logger.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cost_alerts.arn
}
```

**Scheduling Configuration**:
- **Default Schedule**: `rate(6 hours)` (every 6 hours)
- **Alternative Options**: 
  - `rate(1 hour)` - hourly monitoring
  - `cron(0 9 * * ? *)` - daily at 9 AM
  - `cron(0 */4 * * ? *)` - every 4 hours

**Flow Process**:
1. EventBridge rule triggers on schedule
2. Sends message to SNS topic
3. SNS distributes to both email and Lambda function
4. Lambda processes message and logs to DynamoDB

**Security Features**:
- Cross-service permissions properly configured
- Account-specific conditions to prevent external access
- Least privilege access for all services

---

### 11. **`api_gateway.tf`** - REST API Configuration

**Purpose**: Creates REST API endpoint for dashboard data access

**Resource Definitions**:
```hcl
# API Gateway
resource "aws_api_gateway_rest_api" "cost_tracker_api" {
  name        = "${var.project_name}-api"
  description = "API for Cloud Cost Tracker"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  }
}

# API Gateway Method (root resource)
resource "aws_api_gateway_method" "get_cost_data" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  http_method = aws_api_gateway_method.get_cost_data.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cost_tracker_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "cost_tracker_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  stage_name  = var.environment

  lifecycle {
    create_before_destroy = true
  }
}
```

**API Configuration**:
- **Endpoint Type**: Regional (better for single-region usage)
- **Method**: GET (read-only data access)
- **Authorization**: None (public access)
- **Integration**: AWS_PROXY (direct Lambda integration)
- **Stage**: Environment-based (dev/prod)

**URL Structure**:
```
https://[api-id].execute-api.[region].amazonaws.com/[stage]/
```

**Response Format**:
```json
[
  {
    "id": "2024-01-15T10:30:00.000Z",
    "message": "Cost threshold exceeded: $15.50"
  },
  {
    "id": "2024-01-15T04:30:00.000Z", 
    "message": "Scheduled cost check: All systems normal"
  }
]
```

---

### 12. **`s3_cloudfront.tf`** - Static Website Hosting Configuration

**Purpose**: Hosts the web dashboard with global CDN distribution

**Resource Definitions**:
```hcl
# S3 Bucket for static website
resource "aws_s3_bucket" "dashboard_bucket" {
  bucket = "${var.project_name}-dashboard-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-dashboard"
    Environment = var.environment
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "dashboard_bucket_pab" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "dashboard_website" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy for public read access
resource "aws_s3_bucket_policy" "dashboard_bucket_policy" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.dashboard_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.dashboard_bucket_pab]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "dashboard_distribution" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.dashboard_website.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.dashboard_bucket.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.dashboard_bucket.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Custom error response for SPA
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-cloudfront"
    Environment = var.environment
  }
}

# Upload HTML file to S3
resource "aws_s3_object" "dashboard_html" {
  bucket       = aws_s3_bucket.dashboard_bucket.id
  key          = "index.html"
  source       = "${path.module}/frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/frontend/index.html")
}
```

**S3 Configuration**:
- **Bucket Name**: Unique with random suffix
- **Website Hosting**: Enabled with index.html as default
- **Public Access**: Read-only access to website files
- **Security**: Public access only to specific bucket contents

**CloudFront Configuration**:
- **Distribution Type**: Web distribution for static content
- **Origin**: S3 website endpoint
- **HTTPS**: Forced redirect for all traffic
- **Caching**: 1-hour default, 24-hour maximum
- **Compression**: Enabled for faster loading
- **Price Class**: PriceClass_100 (North America & Europe)
- **Error Handling**: SPA-friendly (404s redirect to index.html)

**Performance Features**:
- Global edge locations for fast access
- Automatic compression
- Browser and edge caching
- IPv6 support

---

## ⚡ Lambda Functions

### 1. **`lambda/cost_logger.py`** - Cost Alert Logger

**Purpose**: Processes SNS messages and stores cost alerts in DynamoDB

**Code Structure**:
```python
import boto3
import json
import os
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("DDB_TABLE", "CostTrackerLogs")
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    timestamp = datetime.utcnow().isoformat()

    # Simplify message extraction
    message = event.get("Records", [{}])[0].get("Sns", {}).get("Message", "Test alert")

    table.put_item(Item={
        "id": timestamp,
        "message": message
    })

    return {"statusCode": 200, "body": "Log stored"}
```

**Function Behavior**:
- **Trigger**: SNS topic messages (from CloudWatch alarms or EventBridge)
- **Input**: SNS event with message payload
- **Processing**: Extracts message and creates timestamp
- **Output**: Stores entry in DynamoDB table
- **Error Handling**: Basic error logging via CloudWatch

**Event Processing**:
1. Receives SNS event from trigger
2. Extracts message from event structure
3. Creates ISO timestamp for unique ID
4. Stores record in DynamoDB
5. Returns success response

**Environment Variables**:
- `DDB_TABLE`: DynamoDB table name (set by Terraform)

---

### 2. **`lambda/api_handler.py`** - REST API Handler

**Purpose**: Serves cost data to the web dashboard via REST API

**Code Structure**:
```python
import boto3
import json
import os

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("DDB_TABLE", "CostTrackerLogs")
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    response = table.scan(Limit=10)
    items = response.get("Items", [])
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(items)
    }
```

**Function Behavior**:
- **Trigger**: API Gateway HTTP requests
- **Input**: HTTP GET request from dashboard
- **Processing**: Queries DynamoDB for recent cost logs
- **Output**: JSON array of cost log entries
- **Limits**: Returns maximum 10 most recent entries

**Response Format**:
```json
[
  {
    "id": "2024-01-15T10:30:00.000Z",
    "message": "Cost threshold exceeded: $15.50"
  },
  {
    "id": "2024-01-15T04:30:00.000Z",
    "message": "Scheduled cost check: All systems normal"
  }
]
```

**API Integration**:
- **Method**: GET requests only
- **CORS**: Configured via API Gateway
- **Authentication**: None (public access)
- **Rate Limiting**: Handled by API Gateway

---

### 3. **`lambda/requirements.txt`** - Python Dependencies

**Purpose**: Specifies required Python packages for Lambda functions

**Dependencies**:
```
boto3>=1.26.0
botocore>=1.29.0
```

**Package Details**:
- **boto3**: AWS SDK for Python (high-level API)
- **botocore**: Core AWS functionality (low-level API)
- **Version Constraints**: Minimum versions for compatibility

**Deployment Notes**:
- Lambda includes boto3/botocore by default
- Explicit versions ensure consistency
- No additional packages needed for basic functionality

---

## 🌐 Frontend Dashboard

### **`frontend/index.html`** - Interactive Web Dashboard

**Purpose**: Provides user interface for viewing cost alerts and system status

**Structure Overview**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Styling and Configuration -->
</head>
<body>
    <!-- Header -->
    <!-- Main Content -->
    <!-- JavaScript Logic -->
</body>
</html>
```

**Key Sections**:

#### HTML Structure
```html
<header class="bg-cwa-dark text-white py-4 px-5 text-center text-2xl font-bold">
    CWA Cost Tracker Dashboard
</header>

<main class="max-w-4xl mx-auto my-5 p-5 bg-white rounded-lg shadow-lg">
    <h2 class="text-2xl font-bold text-cwa-blue mb-4">Latest Cost Alerts</h2>
    
    <!-- Loading State -->
    <div id="loading" class="text-center py-8 text-gray-600">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-cwa-blue mx-auto mb-4"></div>
        <p>Loading cost alerts...</p>
    </div>

    <!-- Error State -->
    <div id="error" class="hidden bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
        <h3 class="font-bold">⚠️ Error Loading Data</h3>
        <p id="error-message"></p>
    </div>

    <!-- Logs Container -->
    <div id="logs" class="mt-4 max-h-96 overflow-y-auto border border-gray-300 rounded-lg p-4 bg-gray-50">
        Loading logs...
    </div>

    <!-- Refresh Button -->
    <button onclick="loadLogs()" 
            class="mt-4 bg-cwa-blue hover:bg-blue-700 text-white font-bold py-2 px-4 rounded transition duration-200 ease-in-out transform hover:scale-105">
        🔄 Refresh Logs
    </button>

    <!-- Stats Cards -->
    <div id="stats" class="hidden grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
        <div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
            <div class="text-2xl font-bold text-cwa-blue" id="total-alerts">0</div>
            <div class="text-sm text-gray-600">Total Alerts</div>
        </div>
        <div class="bg-green-50 p-4 rounded-lg border border-green-200">
            <div class="text-2xl font-bold text-green-600" id="recent-alerts">0</div>
            <div class="text-sm text-gray-600">Recent Alerts</div>
        </div>
        <div class="bg-yellow-50 p-4 rounded-lg border border-yellow-200">
            <div class="text-2xl font-bold text-yellow-600" id="last-alert">-</div>
            <div class="text-sm text-gray-600">Last Alert</div>
        </div>
    </div>
</main>
```

#### CSS Styling (Tailwind CSS)
```html
<script src="https://cdn.tailwindcss.com"></script>
<script>
    tailwind.config = {
        theme: {
            extend: {
                colors: {
                    'cwa-blue': '#005EB8',
                    'cwa-dark': '#232f3e'
                }
            }
        }
    }
</script>
```

**Design Features**:
- **Modern UI**: Tailwind CSS for professional appearance
- **Responsive Design**: Works on desktop and mobile
- **Loading States**: Visual feedback during data fetching
- **Error Handling**: User-friendly error messages
- **Interactive Elements**: Hover effects and transitions

#### JavaScript Functionality
```javascript
const API_BASE_URL = 'https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev';

async function loadLogs() {
    try {
        showLoading(true);
        hideError();

        const response = await fetch(API_BASE_URL);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        displayLogs(data);

    } catch (error) {
        console.error('Error loading logs:', error);
        showError('Failed to load cost alerts. Please check your API configuration and try again.');
    } finally {
        showLoading(false);
    }
}

function displayLogs(logs) {
    const logsContainer = document.getElementById('logs');
    const statsContainer = document.getElementById('stats');

    if (logs.length === 0) {
        logsContainer.innerHTML = `
            <div class="text-center py-8 text-gray-500">
                <div class="text-4xl mb-2">📊</div>
                <p>No cost alerts found.</p>
                <p class="text-sm">All systems are running within normal cost parameters.</p>
            </div>
        `;
        return;
    }

    // Display logs
    logsContainer.innerHTML = logs.map(item => `
        <div class="log-entry bg-white p-4 mb-3 rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow duration-200">
            <div class="flex items-start justify-between">
                <div class="flex-1">
                    <div class="font-semibold text-gray-800 mb-1">${item.message}</div>
                    <div class="text-sm text-gray-500">
                        <strong>Time:</strong> ${new Date(item.id).toLocaleString()}
                    </div>
                </div>
                <div class="ml-4">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                        Alert
                    </span>
                </div>
            </div>
        </div>
    `).join('');

    // Update stats
    updateStats(logs);
    statsContainer.classList.remove('hidden');
}

function updateStats(logs) {
    document.getElementById('total-alerts').textContent = logs.length;
    
    // Count recent alerts (last 24 hours)
    const now = new Date();
    const recentAlerts = logs.filter(log => {
        const logTime = new Date(log.id);
        return (now - logTime) < 24 * 60 * 60 * 1000; // 24 hours
    });
    document.getElementById('recent-alerts').textContent = recentAlerts.length;
    
    // Last alert time
    if (logs.length > 0) {
        const lastAlert = new Date(logs[0].id);
        document.getElementById('last-alert').textContent = lastAlert.toLocaleTimeString();
    }
}
```

**JavaScript Features**:
- **Async/Await**: Modern asynchronous programming
- **Error Handling**: Try-catch blocks with user feedback
- **DOM Manipulation**: Dynamic content updates
- **Data Processing**: Statistics calculation and formatting
- **Event Handling**: Button clicks and page load events

**User Interface Elements**:
1. **Header**: Project branding and title
2. **Loading Spinner**: Visual feedback during API calls
3. **Error Messages**: User-friendly error display
4. **Log Entries**: Individual cost alert cards
5. **Statistics Cards**: Summary metrics (total, recent, last alert)
6. **Refresh Button**: Manual data reload
7. **Responsive Layout**: Mobile-friendly design

---

## 📚 Setup & Configuration Files

### **`terraform.tfvars`** - Configuration Values

**Purpose**: Contains actual configuration values for deployment

**Example Content**:
```hcl
aws_region         = "us-east-1"
project_name       = "cost-tracker"
cost_threshold     = 10.00
notification_email = "samueldivine2021@gmail.com"
schedule_expression = "rate(6 hours)"
environment        = "dev"
```

**Configuration Options**:
- **aws_region**: AWS region for all resources
- **project_name**: Prefix for resource names
- **cost_threshold**: Dollar amount for alert threshold
- **notification_email**: Email for alerts (required)
- **schedule_expression**: EventBridge schedule format
- **environment**: Environment name (dev/staging/prod)

### **`terraform.tfvars.example`** - Configuration Template

**Purpose**: Provides template for creating actual configuration

**Usage**:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### **`setup.ps1`** - PowerShell Setup Checker

**Purpose**: Validates prerequisites and environment setup

**Functionality**:
```powershell
# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Check Terraform
if (Test-Command "terraform") {
    $terraformVersion = terraform version
    Write-Host "✅ Terraform: $($terraformVersion.Split("`n")[0])" -ForegroundColor Green
} else {
    Write-Host "❌ Terraform: Not installed" -ForegroundColor Red
}

# Check AWS CLI
if (Test-Command "aws") {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI: $($awsVersion.Split("`n")[0])" -ForegroundColor Green
} else {
    Write-Host "❌ AWS CLI: Not installed" -ForegroundColor Red
}

# Check AWS Configuration
try {
    $awsIdentity = aws sts get-caller-identity 2>$null
    if ($awsIdentity) {
        $accountId = ($awsIdentity | ConvertFrom-Json).Account
        Write-Host "✅ AWS CLI configured for Account: $accountId" -ForegroundColor Green
    } else {
        Write-Host "❌ AWS CLI not configured" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ AWS CLI not configured" -ForegroundColor Red
}
```

**Checks Performed**:
1. Administrator privileges
2. Terraform installation and version
3. AWS CLI installation and version
4. Git installation (optional)
5. AWS CLI configuration
6. terraform.tfvars file existence
7. Terraform initialization status

### **`check-setup.bat`** - Windows Batch Wrapper

**Purpose**: Provides easy access to PowerShell setup checker

**Content**:
```batch
@echo off
echo.
echo 🚀 Cloud Cost Tracker Setup Checker
echo ===================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PowerShell not available
    echo Please install PowerShell or run the commands manually
    pause
    exit /b 1
)

REM Run the PowerShell setup script
powershell -ExecutionPolicy Bypass -File "setup.ps1"

pause
```

### **`test-terraform.ps1`** - Terraform Installation Tester

**Purpose**: Specifically tests Terraform installation and functionality

**Test Coverage**:
1. Command availability check
2. PATH environment variable verification
3. Official HashiCorp version validation
4. Configuration file detection
5. Initialization capability testing

---

## 📖 Documentation Files

### **`README.md`** - Main Project Documentation

**Sections Covered**:
- Project overview and architecture
- Quick start guide
- Configuration options
- Testing procedures
- Troubleshooting guide
- Cost optimization tips

### **`SETUP_GUIDE.md`** - Detailed Installation Guide

**Complete Walkthrough**:
1. Prerequisites installation (Terraform, AWS CLI, Git)
2. AWS account setup and IAM configuration
3. Cost Explorer enablement
4. Project configuration
5. Deployment process
6. Frontend updates
7. Testing procedures

### **`architecture.md`** - Technical Architecture Documentation

**Content**:
- System architecture diagram (Mermaid format)
- Component descriptions
- Data flow patterns
- Security considerations
- Scalability features
- Cost optimization strategies

### **Other Documentation Files**:
- **`DEPLOYMENT.md`**: Deployment-specific instructions
- **`SECURITY_IMPROVEMENTS.md`**: Security best practices
- **`SECURE_SETUP_GUIDE.md`**: Security-focused setup process
- **`UPDATED_SYSTEM.md`**: System updates and changelog
- **`QUICK_REFERENCE.md`**: Quick command reference

---

## 🚀 Deployment Process

### **Step 1: Prerequisites**
```bash
# Install Terraform
# Install AWS CLI
# Configure AWS credentials
aws configure
```

### **Step 2: Configuration**
```bash
# Navigate to project directory
cd cloud-cost-tracker

# Create configuration file
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
notepad terraform.tfvars
```

### **Step 3: Infrastructure Deployment**
```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### **Step 4: Frontend Update**
```bash
# Get API Gateway URL from output
terraform output api_gateway_url

# Update frontend/index.html with API URL
# Replace YOUR_API_GATEWAY_URL with actual URL

# Re-deploy frontend
terraform apply
```

### **Step 5: Verification**
```bash
# Get dashboard URL
terraform output dashboard_url

# Test API endpoint
curl [api-gateway-url]

# Check DynamoDB
aws dynamodb scan --table-name cost-tracker-cost-logs
```

---

## 🧪 Testing & Validation

### **Automated Tests**
```bash
# Run setup checker
.\setup.ps1

# Test Terraform installation
.\test-terraform.ps1

# Validate Terraform configuration
terraform validate

# Plan deployment (dry run)
terraform plan
```

### **Manual Testing**

#### **Lambda Function Testing**
1. Go to AWS Lambda Console
2. Find `cost-tracker-cost-logger` function
3. Create test event:
```json
{
  "Records": [
    {
      "Sns": {
        "Message": "Test cost alert: $15.50"
      }
    }
  ]
}
```
4. Execute test and verify DynamoDB entry

#### **API Testing**
```bash
# Test API endpoint
curl https://[your-api-id].execute-api.us-east-1.amazonaws.com/dev

# Expected response
[
  {
    "id": "2024-01-15T10:30:00.000Z",
    "message": "Test cost alert: $15.50"
  }
]
```

#### **Dashboard Testing**
1. Visit CloudFront URL from terraform output
2. Verify data loads correctly
3. Test refresh functionality
4. Check responsive design

#### **Alert Testing**
1. Lower cost threshold: `cost_threshold = 0.01`
2. Run `terraform apply`
3. Wait for CloudWatch alarm to trigger
4. Verify email notification received
5. Check DynamoDB for logged alert

### **Monitoring Commands**
```bash
# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/cost-tracker

# Check DynamoDB table
aws dynamodb describe-table --table-name cost-tracker-cost-logs

# Check API Gateway
aws apigateway get-rest-apis

# Check SNS topics
aws sns list-topics

# Check EventBridge rules
aws events list-rules
```

---

## 🔧 Troubleshooting Guide

### **Common Issues and Solutions**

#### **1. Terraform Issues**
```bash
# Issue: Terraform not found
# Solution: Add to PATH and restart shell
echo $PATH
export PATH=$PATH:/path/to/terraform

# Issue: Provider initialization failed
# Solution: Re-initialize Terraform
terraform init -upgrade

# Issue: State lock error
# Solution: Force unlock (use carefully)
terraform force-unlock [LOCK_ID]
```

#### **2. AWS Configuration Issues**
```bash
# Issue: Access denied errors
# Solution: Check AWS credentials
aws sts get-caller-identity

# Issue: Cost Explorer not enabled
# Solution: Enable in AWS Console
# Go to Billing -> Cost Explorer -> Enable

# Issue: SNS subscription not confirmed
# Solution: Check email and confirm subscription
```

#### **3. Lambda Function Issues**
```bash
# Issue: Function timeout
# Solution: Increase timeout in lambda.tf
timeout = 60  # Increase as needed

# Issue: Permission denied
# Solution: Check IAM role permissions
# Verify lambda_policy in iam.tf

# Issue: Environment variables missing
# Solution: Verify environment block in lambda.tf
```

#### **4. Dashboard Issues**
```bash
# Issue: API Gateway 502 error
# Solution: Check Lambda function logs
aws logs get-log-events --log-group-name /aws/lambda/cost-tracker-api-handler

# Issue: CloudFront not serving updated content
# Solution: Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id [DIST_ID] --paths "/*"

# Issue: Dashboard not loading
# Solution: Check S3 bucket policy allows public read
```

#### **5. Cost Alert Issues**
```bash
# Issue: Alerts not triggering
# Solution: Check CloudWatch alarm configuration
aws cloudwatch describe-alarms --alarm-names cost-tracker-billing-alarm

# Issue: Email not received
# Solution: Confirm SNS subscription
aws sns list-subscriptions

# Issue: DynamoDB not updating
# Solution: Check Lambda function permissions for DynamoDB
```

### **Debug Commands**
```bash
# View all resources created
terraform show

# Check resource status
terraform state list

# View specific resource
terraform state show aws_lambda_function.cost_logger

# Get detailed output
terraform output -json

# Check AWS service limits
aws service-quotas list-service-quotas --service-code lambda
```

### **Performance Optimization**
```bash
# Optimize Lambda memory allocation
# Edit lambda.tf and add:
memory_size = 256  # Increase for better performance

# Optimize DynamoDB performance
# Already using pay-per-request for auto-scaling

# Optimize CloudFront caching
# Adjust TTL values in s3_cloudfront.tf
default_ttl = 3600    # 1 hour
max_ttl     = 86400   # 24 hours
```

### **Security Hardening**
```bash
# Implement API authentication
# Add API key requirement to api_gateway.tf

# Restrict S3 bucket access
# Implement bucket policies with IP restrictions

# Enable CloudTrail logging
# Add cloudtrail.tf for audit logging

# Implement encryption
# Add KMS keys for DynamoDB and Lambda
```

---

## 💰 Cost Analysis

### **Estimated Monthly Costs (Within Free Tier)**

| Service | Usage | Free Tier | Estimated Cost |
|---------|-------|-----------|----------------|
| DynamoDB | 10 reads/day | 25 RCU/WCU | $0.00 |
| Lambda | 1,440 executions/month | 1M requests | $0.00 |
| S3 | 1 GB storage | 5 GB | $0.00 |
| CloudFront | 100 GB transfer | 1 TB | $0.00 |
| API Gateway | 1,000 calls/month | 1M calls | $0.00 |
| SNS | 10 notifications/month | 1M requests | $0.00 |
| EventBridge | 1,440 events/month | Free | $0.00 |
| CloudWatch | Standard metrics | Free | $0.00 |

**Total Estimated Cost: $0-5/month** (within AWS Free Tier)

### **Scaling Considerations**

| Component | Scaling Method | Cost Impact |
|-----------|---------------|-------------|
| DynamoDB | Auto-scaling | Pay-per-request |
| Lambda | Automatic | Pay-per-execution |
| API Gateway | Automatic | Pay-per-request |
| CloudFront | Global | Pay-per-GB transferred |
| S3 | Unlimited | Pay-per-GB stored |

---

This documentation provides a complete reference for understanding, deploying, maintaining, and troubleshooting your Cloud Cost Tracker system. Each component is thoroughly documented with practical examples and real-world usage scenarios.
