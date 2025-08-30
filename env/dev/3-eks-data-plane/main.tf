locals {
  common_tags = {
    Customer    = var.customer_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Layer       = "eks-data-plane"
  }
  
  # Kubernetes version to AMI type mapping
  k8s_version = data.terraform_remote_state.eks_control_plane.outputs.cluster_version
  
  # AMI type selection based on Kubernetes version
  ami_type = local.k8s_version >= "1.33" ? "AL2023_x86_64_STANDARD" : "AL2_x86_64"
  
  # Validation checks for required remote state outputs
  node_role_arn = data.terraform_remote_state.base_infrastructure.outputs.node_group_role_arn
  private_subnets = data.terraform_remote_state.base_infrastructure.outputs.private_subnet_ids
  node_sg_id = data.terraform_remote_state.base_infrastructure.outputs.node_group_security_group_id
}

# Data sources to get outputs from previous layers
data "terraform_remote_state" "base_infrastructure" {
  backend = "s3"
  config = {
    bucket = "eks-without-ip-limit-bucket"
    key    = "eks-without-ip-limit/dev/1-base-infrastructure/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "eks_control_plane" {
  backend = "s3"
  config = {
    bucket = "eks-without-ip-limit-bucket"
    key    = "eks-without-ip-limit/dev/2-eks-control-plane/terraform.tfstate"
    region = "us-east-2"
  }
}

# Get EKS cluster info
data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = local.node_role_arn
  subnet_ids      = local.private_subnets

  capacity_type        = var.node_group_capacity_type
  instance_types       = var.node_group_instance_types
  ami_type            = local.ami_type
  disk_size           = 20

  dynamic "remote_access" {
    for_each = var.node_group_key_name != null ? [1] : []
    content {
      ec2_ssh_key = var.node_group_key_name
      source_security_group_ids = [local.node_sg_id]
    }
  }

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  # Explicit dependencies to ensure proper creation order
  depends_on = [
    data.terraform_remote_state.base_infrastructure,
    data.terraform_remote_state.eks_control_plane
  ]

  tags = local.common_tags

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  timeouts {
    create = "15m"
    delete = "15m"
    update = "15m"
  }
}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_versions.vpc_cni == "auto" ? null : var.addon_versions.vpc_cni
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = null

  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET      = "1"
    }
  })

  depends_on = [aws_eks_node_group.main]

  tags = local.common_tags

  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.addon_versions.core_dns == "auto" ? null : var.addon_versions.core_dns
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = local.common_tags

  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_versions.kube_proxy == "auto" ? null : var.addon_versions.kube_proxy
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = local.common_tags

  timeouts {
    create = "10m"
    delete = "10m"
    update = "10m"
  }
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = local.common_tags

  timeouts {
    create = "10m"
    delete = "10m" 
    update = "10m"
  }
}