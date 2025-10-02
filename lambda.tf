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
      DDB_TABLE      = aws_dynamodb_table.cost_logs.name
      SNS_TOPIC_ARN  = aws_sns_topic.cost_alerts.arn
    }
  }

  tags = {
    Name        = "${var.project_name}-api-handler"
    Environment = var.environment
  }
}
