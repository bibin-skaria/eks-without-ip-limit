# Base Infrastructure Configuration for EKS Production Environment
# This layer creates VPC, subnets, security groups, and supporting infrastructure

# Tagging and Naming
customer_name = "your-company"
project_name  = "eks-without-ip-limit"
environment   = "prod"

# Infrastructure name prefix (used for VPC, subnets, security groups naming)
infrastructure_name = "eks-prod-custom"

# Network Configuration
vpc_cidr                     = "10.2.0.0/16"
az_count                     = 3  # More AZs for production HA
enable_cni_custom_networking = false

# Security Configuration
enable_kms_encryption = true  # Enable encryption for production

# Monitoring Configuration (CloudWatch resources for future EKS cluster)
enable_cloudwatch_logs = true
log_retention_days     = 90  # Longer retention for production