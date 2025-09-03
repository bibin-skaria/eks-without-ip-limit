# DEV Environment Variable Overrides
# Customize these values for your development environment

# AWS Configuration
region       = "us-east-2"
cluster_name = "eks-dev-custom"
environment  = "dev"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
az_count = 2

# Node Group Configuration - Optimized for dev (cost-effective)
node_group_instance_types   = ["t3.small"]
node_group_capacity_type    = "SPOT"  # Use spot instances for cost savings
node_group_desired_size     = 1
node_group_max_size         = 3
node_group_min_size         = 1

# Security Configuration - More permissive for dev
enable_kms_encryption    = false
public_access_cidrs      = ["0.0.0.0/0"]

# EKS Features
enable_cni_custom_networking = false  # Disabled for stability
enable_prefix_delegation     = true   # Enabled for high pod density
enable_ebs_csi               = true

