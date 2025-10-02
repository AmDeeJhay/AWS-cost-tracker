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
