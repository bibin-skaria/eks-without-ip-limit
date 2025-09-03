output "node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "EKS node group status"
  value       = aws_eks_node_group.main.status
}

output "vpc_cni_addon_arn" {
  description = "VPC CNI addon ARN"
  value       = aws_eks_addon.vpc_cni.arn
}

output "coredns_addon_arn" {
  description = "CoreDNS addon ARN"
  value       = aws_eks_addon.coredns.arn
}

output "kube_proxy_addon_arn" {
  description = "kube-proxy addon ARN"
  value       = aws_eks_addon.kube_proxy.arn
}

output "ebs_csi_addon_arn" {
  description = "EBS CSI addon ARN"
  value       = var.enable_ebs_csi ? aws_eks_addon.ebs_csi_driver[0].arn : null
}