# EKS Control Plane Configuration for UAT Environment

# Cluster Configuration
cluster_name        = "eks-uat-custom"
kubernetes_version  = "1.33"

# Network Access Configuration
public_access_cidrs = ["0.0.0.0/0"]  # Restrict this in production

# Tagging
customer_name = "your-company"
project_name  = "eks-without-ip-limit"
environment   = "uat"