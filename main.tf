# This file is intentionally left minimal as resources are organized in separate files
# See the following files for specific resource configurations:
# - provider.tf: AWS provider and data sources
# - dynamodb.tf: DynamoDB table for cost logs
# - cloudwatch.tf: CloudWatch billing alarm
# - sns.tf: SNS topic and subscriptions
# - iam.tf: IAM roles and policies
# - lambda.tf: Lambda functions
# - eventbridge.tf: EventBridge rules for scheduling
# - api_gateway.tf: API Gateway configuration
# - s3_cloudfront.tf: S3 bucket and CloudFront distribution
# - outputs.tf: Output values