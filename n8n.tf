# =============================================================================
# N8N APPLICATION MODULE
# =============================================================================
# This file configures the main n8n application using the elasticscale/n8n/aws
# module. This module creates all the necessary AWS resources for running n8n
# including ECS Fargate, Application Load Balancer, EFS storage, and VPC.

# -----------------------------------------------------------------------------
# N8N MODULE CONFIGURATION
# -----------------------------------------------------------------------------

module "n8n" {
  # Module source and version
  source  = "elasticscale/n8n/aws"
  version = "3.0.0"  # Using stable module version
  
  # -----------------------------------------------------------------------------
  # SCALING CONFIGURATION
  # -----------------------------------------------------------------------------
  
  desired_count = var.desired_count  # Number of n8n tasks to run
  
  # Note: The module creates an Application Load Balancer that listens on HTTP
  # port 80. HTTPS termination is handled by CloudFront, not at the ALB level.
  # For direct HTTPS at ALB, you would need to provide certificate_arn.
  
  # -----------------------------------------------------------------------------
  # APPLICATION CONFIGURATION
  # -----------------------------------------------------------------------------
  
  # Container image specification
  # Using a pinned version for stability and predictable deployments
  container_image = "n8nio/n8n:1.102.3"  # Pin to specific version
  
  # Application URL configuration
  # This tells n8n what URL it should expect to be accessed from
  # Important: This must match the CloudFront domain to prevent CORS issues
  url = "https://${aws_cloudfront_distribution.cf.domain_name}"
  
  # -----------------------------------------------------------------------------
  # INFRASTRUCTURE CREATED BY THIS MODULE
  # -----------------------------------------------------------------------------
  # The elasticscale/n8n/aws module creates the following resources:
  # - VPC with public and private subnets
  # - Internet Gateway and NAT Gateway
  # - Security Groups for ALB and ECS tasks
  # - Application Load Balancer (ALB)
  # - ECS Fargate cluster and service
  # - EFS file system for persistent storage
  # - CloudWatch log group for application logs
  # - IAM roles and policies for ECS tasks
  
  # -----------------------------------------------------------------------------
  # OPTIONAL CONFIGURATIONS
  # -----------------------------------------------------------------------------
  # These parameters can be added for advanced configurations:
  #
  # certificate_arn = var.ssl_certificate_arn  # For HTTPS at ALB level
  # fargate_type    = "FARGATE"                # Use regular Fargate instead of SPOT
  # environment_variables = {                  # Custom environment variables
  #   NODE_ENV = "production"
  # }
}
