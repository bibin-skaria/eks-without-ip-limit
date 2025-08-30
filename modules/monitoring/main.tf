resource "aws_cloudwatch_log_group" "cluster_monitoring" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/${var.environment}-monitoring"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}