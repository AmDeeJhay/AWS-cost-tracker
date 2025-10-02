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
