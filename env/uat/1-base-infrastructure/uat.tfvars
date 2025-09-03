# Base Infrastructure Configuration for EKS UAT Environment
# This layer creates VPC, subnets, security groups, and supporting infrastructure

# Tagging and Naming
customer_name = "your-company"
project_name  = "eks-without-ip-limit"
environment   = "uat"

# Infrastructure name prefix (used for VPC, subnets, security groups naming)
infrastructure_name = "eks-uat-custom"

# Network Configuration
vpc_cidr                     = "10.1.0.0/16"
az_count                     = 2
enable_cni_custom_networking = false

# Security Configuration
enable_kms_encryption = false

# Monitoring Configuration (CloudWatch resources for future EKS cluster)
enable_cloudwatch_logs = true
log_retention_days     = 30