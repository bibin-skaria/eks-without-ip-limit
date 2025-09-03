variable "customer_name" {
  description = "Customer/Company name for resource naming"
  type        = string
  default     = "customer"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "eks-without-ip-limit"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "infrastructure_name" {
  description = "Name prefix for infrastructure resources (VPC, subnets, security groups)"
  type        = string
  default     = "eks-dev-custom"
  
  validation {
    condition = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.infrastructure_name)) && length(var.infrastructure_name) <= 100
    error_message = "Infrastructure name must start with a letter, contain only alphanumeric characters and hyphens, and be 100 characters or less."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
  
  validation {
    condition = var.az_count >= 2 && var.az_count <= 6
    error_message = "AZ count must be between 2 and 6 for EKS requirements and AWS limits."
  }
}

variable "enable_cni_custom_networking" {
  description = "Enable AWS VPC CNI custom networking"
  type        = bool
  default     = false
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for EKS secrets"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch log group for monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 30
}