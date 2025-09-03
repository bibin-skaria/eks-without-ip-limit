terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }

  backend "s3" {
    bucket         = "eks-without-ip-limit-bucket"
    key            = "eks-without-ip-limit/prod/2-eks-control-plane/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "eks-without-ip-limit"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}