# UAT Environment Variable Overrides
# Customize these values for your UAT environment

# AWS Configuration
region       = "ap-south-1"
cluster_name = "eks-uat"
environment  = "uat"

# Network Configuration
vpc_cidr = "10.2.0.0/16"
pod_cidr = "10.3.0.0/16"
az_count = 2

# Node Group Configuration - Production-like for UAT testing
node_group_instance_types   = ["t3.medium"]
node_group_capacity_type    = "ON_DEMAND"
node_group_desired_size     = 2
node_group_max_size         = 6
node_group_min_size         = 1

# Security Configuration - More restrictive for UAT
enable_kms_encryption    = true
public_access_cidrs      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
bastion_allowed_cidrs    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

# EKS Features
enable_cni_custom_networking = true
enable_prefix_delegation     = true
enable_ebs_csi               = true

# Bastion Configuration
bastion_instance_type = "t3.micro"