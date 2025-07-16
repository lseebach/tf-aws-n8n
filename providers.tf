# =============================================================================
# TERRAFORM CONFIGURATION
# =============================================================================
# This file configures the required providers and AWS provider settings
# for the n8n deployment on AWS infrastructure.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"  # Use AWS provider version 6.x
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"  # Used for generating random values if needed
    }
  }
  
  # Minimum Terraform version required
  required_version = ">= 1.0"
}

# =============================================================================
# AWS PROVIDER CONFIGURATION
# =============================================================================
# Configure the AWS Provider with the specified region
# Authentication is handled via AWS CLI, environment variables, or IAM roles

provider "aws" {
  region = var.aws_region
  
  # Optional: Add default tags to all resources
  default_tags {
    tags = {
      Project     = "n8n-terraform"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}
