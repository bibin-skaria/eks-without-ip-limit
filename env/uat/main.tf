locals {
  common_tags = {
    Environment = var.environment
    Project     = "eks-without-ip-limit"
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  cluster_name                  = var.cluster_name
  vpc_cidr                      = var.vpc_cidr
  az_count                      = var.az_count
  enable_cni_custom_networking  = var.enable_cni_custom_networking
  common_tags                   = local.common_tags
}

module "security" {
  source = "../../modules/security"

  cluster_name            = var.cluster_name
  vpc_id                  = module.network.vpc_id
  vpc_cidr_block          = module.network.vpc_cidr_block
  enable_kms_encryption   = var.enable_kms_encryption
  common_tags             = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                         = var.cluster_name
  kubernetes_version                   = var.kubernetes_version
  cluster_role_arn                     = module.security.eks_cluster_role_arn
  node_group_role_arn                  = module.security.node_group_role_arn
  public_subnet_ids                    = module.network.public_subnet_ids
  private_subnet_ids                   = module.network.private_subnet_ids
  cluster_security_group_id            = module.security.eks_cluster_security_group_id
  kms_key_arn                          = module.security.kms_key_arn
  public_access_cidrs                  = var.public_access_cidrs
  node_group_capacity_type             = var.node_group_capacity_type
  node_group_instance_types            = var.node_group_instance_types
  node_group_desired_size              = var.node_group_desired_size
  node_group_max_size                  = var.node_group_max_size
  node_group_min_size                  = var.node_group_min_size
  node_group_key_name                  = var.node_group_key_name
  common_tags                          = local.common_tags

  depends_on = [module.network, module.security]
}

module "addons" {
  source = "../../modules/addons"

  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  addon_versions                = var.addon_versions
  enable_ebs_csi                = var.enable_ebs_csi
  enable_cni_custom_networking  = var.enable_cni_custom_networking
  enable_prefix_delegation      = var.enable_prefix_delegation
  oidc_provider_arn             = module.eks.oidc_provider_arn
  oidc_provider_url             = module.eks.oidc_provider_url
  availability_zones            = module.network.availability_zones
  pod_subnet_ids                = module.network.pod_subnet_ids
  node_security_group_id        = module.security.node_group_security_group_id
  common_tags                   = local.common_tags

  depends_on = [module.eks]
}

