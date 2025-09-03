output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.network.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.security.eks_cluster_role_arn
}

output "node_group_role_arn" {
  description = "EKS node group IAM role ARN"
  value       = module.security.node_group_role_arn
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.security.eks_cluster_security_group_id
}

output "node_group_security_group_id" {
  description = "EKS node group security group ID"
  value       = module.security.node_group_security_group_id
}

output "kms_key_arn" {
  description = "KMS key ARN for EKS encryption (null if KMS is disabled)"
  value       = var.enable_kms_encryption ? module.security.kms_key_arn : null
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.monitoring.log_group_name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = module.monitoring.log_group_arn
}