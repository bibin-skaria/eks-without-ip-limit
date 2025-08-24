data "aws_eks_addon_version" "latest" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy", "aws-ebs-csi-driver"])

  addon_name         = each.key
  kubernetes_version = var.kubernetes_version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_versions.vpc_cni == "auto" ? data.aws_eks_addon_version.latest["vpc-cni"].version : var.addon_versions.vpc_cni
  service_account_role_arn    = var.enable_irsa ? aws_iam_role.vpc_cni_irsa[0].arn : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = var.enable_prefix_delegation ? jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  }) : null

  depends_on = [var.cluster_name]

  tags = var.common_tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.addon_versions.core_dns == "auto" ? data.aws_eks_addon_version.latest["coredns"].version : var.addon_versions.core_dns
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [var.cluster_name]

  tags = var.common_tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_versions.kube_proxy == "auto" ? data.aws_eks_addon_version.latest["kube-proxy"].version : var.addon_versions.kube_proxy
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [var.cluster_name]

  tags = var.common_tags
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_ebs_csi ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.latest["aws-ebs-csi-driver"].version
  service_account_role_arn    = var.enable_irsa ? aws_iam_role.ebs_csi_irsa[0].arn : null
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [var.cluster_name]

  tags = var.common_tags
}

data "aws_iam_policy_document" "vpc_cni_assume_role" {
  count = var.enable_irsa ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [var.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "vpc_cni_irsa" {
  count = var.enable_irsa ? 1 : 0

  name               = "${var.cluster_name}-vpc-cni-irsa"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role[0].json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni_irsa" {
  count = var.enable_irsa ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_irsa[0].name
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  count = var.enable_irsa && var.enable_ebs_csi ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [var.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs_csi_irsa" {
  count = var.enable_irsa && var.enable_ebs_csi ? 1 : 0

  name               = "${var.cluster_name}-ebs-csi-irsa"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role[0].json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_irsa" {
  count = var.enable_irsa && var.enable_ebs_csi ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa[0].name
}

# Custom networking disabled - using standard VPC CNI with prefix delegation
# This provides high pod density without the complexity of custom networking