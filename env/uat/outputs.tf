output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "kubeconfig" {
  description = "kubectl config file contents"
  value       = module.eks.kubeconfig
  sensitive   = true
}


output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}