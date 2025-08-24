variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# pod_cidr removed - not needed when custom networking is disabled

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "enable_cni_custom_networking" {
  description = "Enable AWS VPC CNI custom networking"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}