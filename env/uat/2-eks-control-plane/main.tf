locals {
  common_tags = {
    Customer    = var.customer_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Layer       = "eks-control-plane"
  }
}

# Data sources to get outputs from Layer 1
data "terraform_remote_state" "base_infrastructure" {
  backend = "s3"
  config = {
    bucket = "eks-without-ip-limit-bucket"
    key    = "eks-without-ip-limit/uat/1-base-infrastructure/terraform.tfstate"
    region = "us-east-2"
  }
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name                         = var.cluster_name
  kubernetes_version                   = var.kubernetes_version
  cluster_role_arn                     = data.terraform_remote_state.base_infrastructure.outputs.eks_cluster_role_arn
  public_subnet_ids                    = data.terraform_remote_state.base_infrastructure.outputs.public_subnet_ids
  private_subnet_ids                   = data.terraform_remote_state.base_infrastructure.outputs.private_subnet_ids
  cluster_security_group_id            = data.terraform_remote_state.base_infrastructure.outputs.eks_cluster_security_group_id
  kms_key_arn                          = null  # KMS encryption is disabled in base infrastructure
  public_access_cidrs                  = var.public_access_cidrs
  common_tags                          = local.common_tags

  # Add proper timeouts for EKS cluster
  cluster_timeouts = {
    create = "30m"
    delete = "20m"
    update = "30m"
  }
}