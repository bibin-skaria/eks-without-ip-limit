customer_name = "your-company"
project_name  = "eks-without-ip-limit"
region       = "us-east-2"
cluster_name = "eks-dev-custom"
environment  = "dev"

# EKS Configuration
kubernetes_version  = "1.33"
public_access_cidrs = ["0.0.0.0/0"]