# Copy this file to terraform.tfvars and update with your values

aws_region         = "us-east-1"
project_name       = "cost-tracker"
cost_threshold     = 10.00
notification_email = "samueldivine2021@gmail.com"
schedule_expression = "rate(6 hours)"
environment        = "dev"