# =============================================================================
# OUTPUT VALUES
# =============================================================================
# This file defines the outputs that will be displayed after successful
# deployment. These outputs provide essential information for accessing
# and managing the deployed n8n instance.

# -----------------------------------------------------------------------------
# ACCESS INFORMATION
# -----------------------------------------------------------------------------

output "cloudfront_domain" {
  description = "CloudFront domain name for accessing n8n"
  value       = aws_cloudfront_distribution.cf.domain_name
  
  # This output provides the CloudFront domain (e.g., d123456789abcd.cloudfront.net)
  # that serves as the entry point for the n8n application
}

output "n8n_url" {
  description = "Complete HTTPS URL for accessing n8n"
  value       = "https://${aws_cloudfront_distribution.cf.domain_name}"
  
  # This output provides the full URL that users can click to access n8n
  # Example: https://d123456789abcd.cloudfront.net
}

# -----------------------------------------------------------------------------
# INFRASTRUCTURE INFORMATION
# -----------------------------------------------------------------------------

output "deployment_region" {
  description = "AWS region where the infrastructure is deployed"
  value       = var.aws_region
  
  # Shows which AWS region the infrastructure was deployed to
}

output "n8n_version" {
  description = "Version of n8n container being deployed"
  value       = "1.102.3"  # Current pinned version
  
  # Shows the current n8n version being deployed
  # This should be updated when the version in n8n.tf changes
}

# -----------------------------------------------------------------------------
# OPTIONAL OUTPUTS FOR DEBUGGING
# -----------------------------------------------------------------------------
# These outputs can be uncommented if needed for troubleshooting:
#
# output "alb_dns_name" {
#   description = "Application Load Balancer DNS name (for debugging)"
#   value       = module.n8n.lb_dns_name
# }
#
# output "efs_id" {
#   description = "EFS file system ID (for debugging)"
#   value       = module.n8n.efs_id
# }
