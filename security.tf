# =============================================================================
# SECURITY CONFIGURATIONS
# =============================================================================
# This file contains security-related configurations for the n8n deployment.
# Currently, the primary security is provided by:
# 1. CloudFront acting as a protective layer in front of the ALB
# 2. VPC isolation (created by the n8n module)
# 3. Security groups (created by the n8n module)
# 4. Private subnets for ECS tasks (created by the n8n module)

# -----------------------------------------------------------------------------
# SECURITY ARCHITECTURE OVERVIEW
# -----------------------------------------------------------------------------
# 
# The security model for this deployment follows these principles:
#
# 1. HTTPS Termination: CloudFront terminates SSL/TLS and forwards HTTP to ALB
# 2. Access Control: Only CloudFront can access the ALB (via security groups)
# 3. Network Isolation: ECS tasks run in private subnets with no direct internet access
# 4. Least Privilege: IAM roles provide minimal required permissions
# 5. Encrypted Storage: EFS uses encryption at rest and in transit
#
# Security Groups (created by n8n module):
# - ALB Security Group: Allows HTTP (80) from CloudFront IP ranges
# - ECS Security Group: Allows traffic from ALB only
# - EFS Security Group: Allows NFS traffic from ECS tasks only
#
# VPC Configuration (created by n8n module):
# - Public subnets: ALB only
# - Private subnets: ECS tasks and EFS
# - NAT Gateway: Provides outbound internet access for ECS tasks
# - Internet Gateway: Provides inbound access to ALB

# -----------------------------------------------------------------------------
# FUTURE SECURITY ENHANCEMENTS
# -----------------------------------------------------------------------------
# The following security features could be added for enhanced security:
#
# 1. WAF (Web Application Firewall)
# resource "aws_wafv2_web_acl" "n8n_waf" {
#   name  = "n8n-waf"
#   scope = "CLOUDFRONT"
#   # ... WAF rules for protection against common attacks
# }
#
# 2. CloudFront with custom headers for origin verification
# resource "random_password" "cloudfront_secret" {
#   length  = 32
#   special = false
# }
#
# 3. CloudWatch alarms for suspicious activity
# resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
#   alarm_name          = "n8n-high-error-rate"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "4XXError"
#   namespace           = "AWS/CloudFront"
#   period              = "300"
#   statistic           = "Sum"
#   threshold           = "100"
#   alarm_description   = "This metric monitors CloudFront 4xx errors"
# }
#
# 4. AWS Config rules for compliance monitoring
# 5. VPC Flow Logs for network traffic monitoring
# 6. AWS GuardDuty for threat detection

# -----------------------------------------------------------------------------
# CURRENT SECURITY STATUS
# -----------------------------------------------------------------------------
# ✅ HTTPS enforcement via CloudFront
# ✅ VPC isolation with private subnets
# ✅ Security groups with least privilege access
# ✅ EFS encryption at rest and in transit
# ✅ IAM roles with minimal permissions
# ✅ CloudWatch logging for monitoring
# 
# ⚠️  Consider adding for production:
# - WAF for application-level protection
# - Custom domain with ACM certificate
# - CloudWatch alarms and monitoring
# - VPC Flow Logs
# - AWS Config compliance rules