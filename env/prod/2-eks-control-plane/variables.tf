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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-dev-custom"
}

variable "kubernetes_version" {
  description = "Kubernetes version (must be supported by EKS)"
  type        = string
  default     = "1.33"
  
  validation {
    condition = can(regex("^1\\.(3[0-3])$", var.kubernetes_version))
    error_message = "Kubernetes version must be between 1.30 and 1.33 (current EKS support range)."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}