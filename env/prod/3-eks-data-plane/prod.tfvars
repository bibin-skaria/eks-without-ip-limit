# EKS Data Plane Configuration for Production Environment

# Cluster Configuration
cluster_name = "eks-prod-custom"

# Node Group Configuration - Production sizing
node_group_instance_types = ["t3.medium", "t3.large"]  # Larger instances for production
node_group_capacity_type  = "ON_DEMAND"                # On-demand for production stability
node_group_desired_size   = 3                          # Higher baseline for production
node_group_max_size       = 10                         # Higher max for production scaling
node_group_min_size       = 3                          # Higher minimum for HA
node_group_key_name       = null                       # SSH key for node access (optional)

# EKS Addons Configuration
enable_ebs_csi = true
addon_versions = {
  vpc_cni    = "auto"
  core_dns   = "auto"
  kube_proxy = "auto"
}

# Tagging
customer_name = "your-company"
project_name  = "eks-without-ip-limit"
environment   = "prod"