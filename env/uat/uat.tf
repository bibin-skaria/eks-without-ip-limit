# UAT Environment Configuration
# Configure your UAT (User Acceptance Testing) environment variables here

# Backend configuration for remote state
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "eks-without-ip-limit/uat/terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "your-terraform-locks-table"
#     encrypt        = true
#   }
# }

# UAT-specific resources for monitoring and testing
resource "aws_cloudwatch_log_group" "uat_monitoring" {
  name              = "/aws/eks/${var.cluster_name}/uat-monitoring"
  retention_in_days = 30
  tags              = local.common_tags
}