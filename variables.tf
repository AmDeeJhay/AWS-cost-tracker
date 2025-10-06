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
}

variable "ses_sender_email" {
  description = "Verified SES sender email address"
  type        = string
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