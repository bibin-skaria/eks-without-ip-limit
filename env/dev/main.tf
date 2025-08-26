locals {
  common_tags = {
    Environment = var.environment
    Project     = "eks-without-ip-limit"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  cluster_name                 = var.cluster_name
  vpc_cidr                     = var.vpc_cidr
  az_count                     = var.az_count
  enable_cni_custom_networking = var.enable_cni_custom_networking
  common_tags                  = local.common_tags
}

module "security" {
  source = "../../modules/security"

  cluster_name          = var.cluster_name
  vpc_id                = module.network.vpc_id
  vpc_cidr_block        = module.network.vpc_cidr_block
  enable_kms_encryption = var.enable_kms_encryption
  common_tags           = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name              = var.cluster_name
  kubernetes_version        = var.kubernetes_version
  cluster_role_arn          = module.security.eks_cluster_role_arn
  public_subnet_ids         = module.network.public_subnet_ids
  private_subnet_ids        = module.network.private_subnet_ids
  cluster_security_group_id = module.security.eks_cluster_security_group_id
  kms_key_arn               = module.security.kms_key_arn
  public_access_cidrs       = var.public_access_cidrs
  common_tags               = local.common_tags

  depends_on = [module.network, module.security]
}

# Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = module.eks.cluster_id
  node_group_name = "${var.cluster_name}-main"
  node_role_arn   = module.security.node_group_role_arn
  subnet_ids      = module.network.private_subnet_ids

  instance_types = var.node_group_instance_types
  capacity_type  = var.node_group_capacity_type

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  disk_size = 20
  ami_type  = "AL2023_x86_64_STANDARD"

  tags = local.common_tags
}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "vpc-cni"
  addon_version               = "v1.18.1-eksbuild.1" # example valid version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "coredns"
  addon_version               = "v1.11.1-eksbuild.4"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "kube-proxy"
  addon_version               = "v1.31.0-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}












































