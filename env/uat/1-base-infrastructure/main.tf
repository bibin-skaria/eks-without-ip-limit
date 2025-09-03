locals {
  common_tags = {
    Customer    = var.customer_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Layer       = "base-infrastructure"
  }
}

module "network" {
  source = "../../../modules/network"

  cluster_name                  = var.infrastructure_name
  vpc_cidr                      = var.vpc_cidr
  az_count                      = var.az_count
  enable_cni_custom_networking  = var.enable_cni_custom_networking
  common_tags                   = local.common_tags
}

module "security" {
  source = "../../../modules/security"

  cluster_name            = var.infrastructure_name
  vpc_id                  = module.network.vpc_id
  vpc_cidr_block          = module.network.vpc_cidr_block
  enable_kms_encryption   = var.enable_kms_encryption
  common_tags             = local.common_tags
}

module "monitoring" {
  source = "../../../modules/monitoring"

  cluster_name            = var.infrastructure_name
  environment             = var.environment
  enable_cloudwatch_logs  = var.enable_cloudwatch_logs
  log_retention_days      = var.log_retention_days
  common_tags             = local.common_tags
}