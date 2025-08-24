# dev Environment Configuration
# Configure your dev (User Acceptance Testing) environment variables here

# Backend configuration for remote state
terraform {
  backend "s3" {
    bucket         = "eks-without-ip-limit-bucket"
    key            = "eks-without-ip-limit/dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "eks-without-ip-limit"
    encrypt        = true
  }
}

# dev-specific resources for monitoring and testing
resource "aws_cloudwatch_log_group" "dev_monitoring" {
  name              = "/aws/eks/${var.cluster_name}/dev-monitoring"
  retention_in_days = 30
  tags              = local.common_tags
}