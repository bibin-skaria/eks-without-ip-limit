# PROD Environment Configuration
# Configure your production environment variables here

# Backend configuration for remote state
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "eks-without-ip-limit/prod/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "your-terraform-locks-table"
#     encrypt        = true
#   }
# }

# Production-specific resources for compliance and monitoring
resource "aws_cloudwatch_log_group" "prod_audit" {
  name              = "/aws/eks/${var.cluster_name}/audit"
  retention_in_days = 365  # Longer retention for compliance
  tags              = local.common_tags
}

resource "aws_s3_bucket" "prod_backups" {
  bucket = "${var.cluster_name}-prod-backups"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "prod_backups" {
  bucket = aws_s3_bucket.prod_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}