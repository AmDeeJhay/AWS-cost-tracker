# DynamoDB Table
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for cost logs"
  value       = aws_dynamodb_table.cost_logs.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for cost logs"
  value       = aws_dynamodb_table.cost_logs.arn
}

# SNS Topic
output "sns_topic_arn" {
  description = "ARN of the SNS topic for cost alerts"
  value       = aws_sns_topic.cost_alerts.arn
}

# CloudWatch Alarm
output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch billing alarm"
  value       = aws_cloudwatch_metric_alarm.billing_alarm.alarm_name
}

# Lambda Functions
output "cost_logger_function_name" {
  description = "Name of the cost logger Lambda function"
  value       = aws_lambda_function.cost_logger.function_name
}

output "api_handler_function_name" {
  description = "Name of the API handler Lambda function"
  value       = aws_lambda_function.api_handler.function_name
}

# API Gateway
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.cost_tracker_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.cost_tracker_stage.stage_name}"
}

# S3 Bucket
output "s3_bucket_name" {
  description = "Name of the S3 bucket for the dashboard"
  value       = aws_s3_bucket.dashboard_bucket.bucket
}

output "s3_bucket_website_url" {
  description = "Website URL of the S3 bucket"
  value       = "http://${aws_s3_bucket_website_configuration.dashboard_website.website_endpoint}"
}

# CloudFront
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.dashboard_distribution.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.dashboard_distribution.domain_name
}

output "dashboard_url" {
  description = "URL of the CloudFront dashboard"
  value       = "https://${aws_cloudfront_distribution.dashboard_distribution.domain_name}"
}

# EventBridge Rule
output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for scheduling"
  value       = aws_cloudwatch_event_rule.cost_logger_schedule.name
}

# Instructions
output "deployment_instructions" {
  description = "Instructions for completing the deployment"
  value = <<-EOT
    Deployment completed! Here's what you need to do next:
    
    1. Test the system:
       - Visit the dashboard: https://${aws_cloudfront_distribution.dashboard_distribution.domain_name}
       - Manually invoke the cost logger Lambda function
       - Check DynamoDB for logged entries
    
    2. For testing alerts:
       - Lower the cost_threshold in terraform.tfvars to $0.01
       - Run: terraform apply
       - The alarm should trigger quickly for testing
    
    Dashboard URL: https://${aws_cloudfront_distribution.dashboard_distribution.domain_name}
    API URL: https://${aws_api_gateway_rest_api.cost_tracker_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.cost_tracker_stage.stage_name}
  EOT
}
