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
