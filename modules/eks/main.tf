resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [var.cluster_security_group_id]
  }

  dynamic "encryption_config" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.cluster_log_types

  timeouts {
    create = try(var.cluster_timeouts.create, "30m")
    delete = try(var.cluster_timeouts.delete, "20m")
    update = try(var.cluster_timeouts.update, "30m")
  }

  lifecycle {
    ignore_changes = [
      # Prevent unnecessary updates
      tags["CreatedBy"],
      tags["LastModified"]
    ]
  }

  depends_on = [
    var.cluster_role_arn
  ]

  tags = var.common_tags
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}


data "tls_certificate" "main" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.main.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-irsa"
  })
}