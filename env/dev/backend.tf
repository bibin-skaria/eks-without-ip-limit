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