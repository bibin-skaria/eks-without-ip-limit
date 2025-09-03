# EKS Data Plane Configuration for UAT Environment

# Cluster Configuration
cluster_name = "eks-uat-custom"

# Node Group Configuration
node_group_instance_types = ["t3.small"]
node_group_capacity_type  = "SPOT"
node_group_desired_size   = 2
node_group_max_size       = 4
node_group_min_size       = 1
node_group_key_name       = null  # SSH key for node access (optional)

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
environment   = "uat"