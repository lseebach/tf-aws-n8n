# =============================================================================
# CLOUDFRONT DISTRIBUTION
# =============================================================================
# This file configures the CloudFront distribution that provides global CDN
# capabilities, HTTPS termination, and improved performance for the n8n application.
# CloudFront sits in front of the Application Load Balancer and handles all
# incoming traffic from users worldwide.

# -----------------------------------------------------------------------------
# CLOUDFRONT DISTRIBUTION CONFIGURATION
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "cf" {
  enabled             = true  # Enable the distribution
  is_ipv6_enabled     = true  # Enable IPv6 support
  default_root_object = "/"   # Default path when accessing root URL
  
  # Optional: Add comment for identification
  comment = "CloudFront distribution for n8n workflow automation"
  
  # -----------------------------------------------------------------------------
  # ORIGIN CONFIGURATION
  # -----------------------------------------------------------------------------
  # The origin defines where CloudFront fetches content from (the ALB)
  
  origin {
    domain_name = module.n8n.lb_dns_name  # ALB DNS name from n8n module
    origin_id   = "n8n-alb-origin"        # Unique identifier for this origin
    
    # Custom origin configuration for ALB
    custom_origin_config {
      http_port              = 80           # ALB listens on HTTP port 80
      https_port             = 443          # Standard HTTPS port (not used)
      origin_protocol_policy = "http-only"  # Only use HTTP to connect to ALB
      origin_ssl_protocols   = ["TLSv1.2"] # SSL protocol for HTTPS (not used)
      
      # Connection settings
      origin_keepalive_timeout = 5   # Keep connections alive for 5 seconds
      origin_read_timeout      = 30  # Wait up to 30 seconds for response
    }
  }
  
  # -----------------------------------------------------------------------------
  # CACHE BEHAVIOR CONFIGURATION
  # -----------------------------------------------------------------------------
  # Define how CloudFront handles different types of requests
  
  default_cache_behavior {
    target_origin_id       = "n8n-alb-origin"      # Use the ALB origin
    viewer_protocol_policy = "redirect-to-https"   # Force HTTPS for viewers
    compress               = true                   # Enable gzip compression
    
    # HTTP methods that CloudFront accepts and forwards
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]  # Only cache GET and HEAD requests
    
    # Request forwarding configuration
    forwarded_values {
      query_string = true  # Forward query parameters to origin
      
      # Forward essential headers for n8n functionality
      headers = [
        "Authorization",              # Authentication headers
        "CloudFront-Forwarded-Proto", # Protocol information
        "Host"                        # Host header for proper routing
      ]
      
      # Forward all cookies (required for n8n session management)
      cookies {
        forward = "all"
      }
    }
    
    # Cache TTL settings - set to 0 to disable caching for dynamic content
    min_ttl     = 0  # Minimum time to cache objects
    default_ttl = 0  # Default time to cache objects
    max_ttl     = 0  # Maximum time to cache objects
  }
  
  # -----------------------------------------------------------------------------
  # GEOGRAPHIC RESTRICTIONS
  # -----------------------------------------------------------------------------
  # Configure geographic access restrictions (none by default)
  
  restrictions {
    geo_restriction {
      restriction_type = "none"  # No geographic restrictions
      # locations = ["US", "CA", "GB", "DE"]  # Example: restrict to specific countries
    }
  }
  
  # -----------------------------------------------------------------------------
  # SSL CERTIFICATE CONFIGURATION
  # -----------------------------------------------------------------------------
  # Use CloudFront's default SSL certificate for *.cloudfront.net domains
  
  viewer_certificate {
    cloudfront_default_certificate = true  # Use default CloudFront certificate
    
    # For custom domains, use:
    # acm_certificate_arn            = var.ssl_certificate_arn
    # ssl_support_method             = "sni-only"
    # minimum_protocol_version       = "TLSv1.2_2019"
  }
  
  # -----------------------------------------------------------------------------
  # TAGS
  # -----------------------------------------------------------------------------
  
  tags = {
    Name        = "n8n-cloudfront-distribution"
    Environment = "production"
    Purpose     = "CDN for n8n workflow automation"
  }
}
