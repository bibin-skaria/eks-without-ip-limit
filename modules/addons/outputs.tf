output "vpc_cni_addon_arn" {
  description = "ARN of the VPC CNI addon"
  value       = aws_eks_addon.vpc_cni.arn
}

output "coredns_addon_arn" {
  description = "ARN of the CoreDNS addon"
  value       = aws_eks_addon.coredns.arn
}

output "kube_proxy_addon_arn" {
  description = "ARN of the kube-proxy addon"
  value       = aws_eks_addon.kube_proxy.arn
}

output "ebs_csi_addon_arn" {
  description = "ARN of the EBS CSI addon"
  value       = var.enable_ebs_csi ? aws_eks_addon.ebs_csi[0].arn : null
}

output "vpc_cni_irsa_role_arn" {
  description = "ARN of the VPC CNI IRSA role"
  value       = var.enable_irsa ? aws_iam_role.vpc_cni_irsa[0].arn : null
}

output "ebs_csi_irsa_role_arn" {
  description = "ARN of the EBS CSI IRSA role"
  value       = var.enable_irsa && var.enable_ebs_csi ? aws_iam_role.ebs_csi_irsa[0].arn : null
}