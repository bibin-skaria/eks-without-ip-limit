variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where bastion hosts will be deployed"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for bastion hosts"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion hosts"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = null
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager Session Manager access"
  type        = bool
  default     = true
}

variable "min_size" {
  description = "Minimum number of bastion instances"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of bastion instances"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of bastion instances"
  type        = number
  default     = 1
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}