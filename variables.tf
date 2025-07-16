# =============================================================================
# INPUT VARIABLES
# =============================================================================
# This file defines all configurable variables for the n8n deployment.
# These variables allow customization of the deployment without modifying
# the core Terraform configuration.

# -----------------------------------------------------------------------------
# AWS CONFIGURATION
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy the n8n infrastructure into"
  type        = string
  default     = "eu-central-1"
  
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "The aws_region must be a valid AWS region format (e.g., us-east-1, eu-central-1)."
  }
}

# -----------------------------------------------------------------------------
# N8N APPLICATION CONFIGURATION
# -----------------------------------------------------------------------------

variable "desired_count" {
  description = "Number of n8n Fargate tasks to run (for high availability, use 2 or more)"
  type        = number
  default     = 1
  
  validation {
    condition = var.desired_count >= 1 && var.desired_count <= 10
    error_message = "The desired_count must be between 1 and 10."
  }
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES FOR ADVANCED CONFIGURATION
# -----------------------------------------------------------------------------
# These variables can be added in the future for more customization:
#
# variable "environment" {
#   description = "Environment name (e.g., dev, staging, prod)"
#   type        = string
#   default     = "prod"
# }
#
# variable "custom_domain" {
#   description = "Custom domain for n8n (optional)"
#   type        = string
#   default     = ""
# }
#
# variable "ssl_certificate_arn" {
#   description = "ARN of SSL certificate for custom domain"
#   type        = string
#   default     = ""
# }
