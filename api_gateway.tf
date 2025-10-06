# API Gateway
resource "aws_api_gateway_rest_api" "cost_tracker_api" {
  name        = "${var.project_name}-api"
  description = "Modern API for Cloud Cost Tracker with enhanced features"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  }
}

# CORS Configuration
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  http_method = aws_api_gateway_method.options_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Root resource methods (GET for cost data)
resource "aws_api_gateway_method" "get_cost_data" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  http_method = aws_api_gateway_method.get_cost_data.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Dashboard Data Resource
resource "aws_api_gateway_resource" "dashboard_data" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  path_part   = "dashboard-data"
}

resource "aws_api_gateway_method" "dashboard_data_get" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.dashboard_data.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "dashboard_data_options" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.dashboard_data.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "dashboard_data_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.dashboard_data.id
  http_method = aws_api_gateway_method.dashboard_data_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

resource "aws_api_gateway_integration" "dashboard_data_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.dashboard_data.id
  http_method = aws_api_gateway_method.dashboard_data_options.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Update Threshold Resource
resource "aws_api_gateway_resource" "update_threshold" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  path_part   = "update-threshold"
}

resource "aws_api_gateway_method" "update_threshold_post" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.update_threshold.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "update_threshold_options" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.update_threshold.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "update_threshold_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.update_threshold.id
  http_method = aws_api_gateway_method.update_threshold_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

resource "aws_api_gateway_integration" "update_threshold_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.update_threshold.id
  http_method = aws_api_gateway_method.update_threshold_options.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Stop EC2 Resource
resource "aws_api_gateway_resource" "stop_ec2" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  path_part   = "stop-ec2"
}

resource "aws_api_gateway_method" "stop_ec2_post" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.stop_ec2.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "stop_ec2_options" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.stop_ec2.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "stop_ec2_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.stop_ec2.id
  http_method = aws_api_gateway_method.stop_ec2_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

resource "aws_api_gateway_integration" "stop_ec2_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.stop_ec2.id
  http_method = aws_api_gateway_method.stop_ec2_options.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Metrics Resource
resource "aws_api_gateway_resource" "metrics" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  path_part   = "metrics"
}

resource "aws_api_gateway_method" "metrics_get" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.metrics.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "metrics_options" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.metrics.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "metrics_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.metrics.id
  http_method = aws_api_gateway_method.metrics_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

resource "aws_api_gateway_integration" "metrics_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.metrics.id
  http_method = aws_api_gateway_method.metrics_options.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Clear alerts resource
resource "aws_api_gateway_resource" "clear_alerts" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  path_part   = "clear-alerts"
}

# Clear selected alerts resource
resource "aws_api_gateway_resource" "clear_selected_alerts" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  parent_id   = aws_api_gateway_rest_api.cost_tracker_api.root_resource_id
  path_part   = "clear-selected-alerts"
}

# Clear alerts methods
resource "aws_api_gateway_method" "clear_alerts_post" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.clear_alerts.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "clear_alerts_options" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.clear_alerts.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Clear alerts integrations
resource "aws_api_gateway_integration" "clear_alerts_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.clear_alerts.id
  http_method = aws_api_gateway_method.clear_alerts_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

resource "aws_api_gateway_integration" "clear_alerts_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.clear_alerts.id
  http_method = aws_api_gateway_method.clear_alerts_options.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Clear selected alerts methods
resource "aws_api_gateway_method" "clear_selected_alerts_post" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.clear_selected_alerts.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "clear_selected_alerts_options" {
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id   = aws_api_gateway_resource.clear_selected_alerts.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Clear selected alerts integrations
resource "aws_api_gateway_integration" "clear_selected_alerts_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.clear_selected_alerts.id
  http_method = aws_api_gateway_method.clear_selected_alerts_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

resource "aws_api_gateway_integration" "clear_selected_alerts_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id
  resource_id = aws_api_gateway_resource.clear_selected_alerts.id
  http_method = aws_api_gateway_method.clear_selected_alerts_options.http_method

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
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_integration.dashboard_data_integration,
    aws_api_gateway_integration.dashboard_data_options_integration,
    aws_api_gateway_integration.update_threshold_integration,
    aws_api_gateway_integration.update_threshold_options_integration,
    aws_api_gateway_integration.stop_ec2_integration,
    aws_api_gateway_integration.stop_ec2_options_integration,
    aws_api_gateway_integration.metrics_integration,
    aws_api_gateway_integration.metrics_options_integration,
    aws_api_gateway_integration.clear_alerts_integration,
    aws_api_gateway_integration.clear_alerts_options_integration,
    aws_api_gateway_integration.clear_selected_alerts_integration,
    aws_api_gateway_integration.clear_selected_alerts_options_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.cost_tracker_api.id

  lifecycle {
    create_before_destroy = true
  }
  
  # Force redeployment by changing this timestamp
  triggers = {
    redeployment = "2025-10-06T16:10:00Z"
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "cost_tracker_stage" {
  deployment_id = aws_api_gateway_deployment.cost_tracker_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.cost_tracker_api.id
  stage_name    = var.environment

  tags = {
    Name        = "${var.project_name}-${var.environment}-stage"
    Environment = var.environment
  }
}
