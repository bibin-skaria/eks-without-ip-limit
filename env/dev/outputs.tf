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

output "private_subnet_ids" {
  description = "Private subnet IDs for node group creation"
  value       = module.network.private_subnet_ids
}

output "node_group_role_arn" {
  description = "ARN of the node group IAM role"
  value       = module.security.node_group_role_arn
}

output "create_node_group_command" {
  description = "AWS CLI command to create node group"
  value = "aws eks create-nodegroup --cluster-name ${var.cluster_name} --nodegroup-name ${var.cluster_name}-main --subnets ${join(" ", module.network.private_subnet_ids)} --instance-types ${join(",", var.node_group_instance_types)} --capacity-type ${var.node_group_capacity_type} --scaling-config minSize=${var.node_group_min_size},maxSize=${var.node_group_max_size},desiredSize=${var.node_group_desired_size} --disk-size 20 --ami-type AL2023_x86_64_STANDARD --node-role ${module.security.node_group_role_arn} --region ${var.region}"
}

output "create_addons_commands" {
  description = "AWS CLI commands to create EKS addons"
  value = [
    "aws eks create-addon --cluster-name ${var.cluster_name} --addon-name vpc-cni --resolve-conflicts OVERWRITE --configuration-values '{\"env\":{\"ENABLE_PREFIX_DELEGATION\":\"true\",\"WARM_PREFIX_TARGET\":\"1\"}}' --region ${var.region}",
    "aws eks create-addon --cluster-name ${var.cluster_name} --addon-name coredns --resolve-conflicts OVERWRITE --region ${var.region}",
    "aws eks create-addon --cluster-name ${var.cluster_name} --addon-name kube-proxy --resolve-conflicts OVERWRITE --region ${var.region}",
    "aws eks create-addon --cluster-name ${var.cluster_name} --addon-name aws-ebs-csi-driver --resolve-conflicts OVERWRITE --region ${var.region}"
  ]
}