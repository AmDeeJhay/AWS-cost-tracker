# DynamoDB Table for cost logs
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
