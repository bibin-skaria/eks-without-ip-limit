# EKS Control Plane Configuration for Production Environment

# Cluster Configuration
cluster_name        = "eks-prod-custom"
kubernetes_version  = "1.33"

# Network Access Configuration
public_access_cidrs = ["203.0.113.0/24"]  # Restrict to your office/VPN CIDR

# Tagging
customer_name = "your-company"
project_name  = "eks-without-ip-limit"
environment   = "prod"