output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.node_group_role.arn
}

output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_group_security_group_id" {
  description = "Security group ID for EKS node group"
  value       = aws_security_group.node_group.id
}


output "kms_key_arn" {
  description = "ARN of the KMS key for EKS encryption"
  value       = var.enable_kms_encryption ? aws_kms_key.eks[0].arn : null
}

output "kms_key_id" {
  description = "ID of the KMS key for EKS encryption"
  value       = var.enable_kms_encryption ? aws_kms_key.eks[0].key_id : null
}