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

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "enable_ebs_csi" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "addon_versions" {
  description = "EKS addon versions"
  type = object({
    vpc_cni    = string
    core_dns   = string
    kube_proxy = string
  })
  default = {
    vpc_cni    = "auto"
    core_dns   = "auto"
    kube_proxy = "auto"
  }
}

variable "node_group_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
  
  validation {
    condition = length(var.node_group_instance_types) > 0 && length(var.node_group_instance_types) <= 20
    error_message = "Must specify between 1 and 20 instance types for node group."
  }
}

variable "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition = contains(["ON_DEMAND", "SPOT"], var.node_group_capacity_type)
    error_message = "Node group capacity type must be either 'ON_DEMAND' or 'SPOT'."
  }
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
  
  validation {
    condition = var.node_group_desired_size >= 0 && var.node_group_desired_size <= 100
    error_message = "Desired size must be between 0 and 100."
  }
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 4
  
  validation {
    condition = var.node_group_max_size >= 1 && var.node_group_max_size <= 100
    error_message = "Max size must be between 1 and 100."
  }
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
  
  validation {
    condition = var.node_group_min_size >= 0 && var.node_group_min_size <= 100
    error_message = "Min size must be between 0 and 100."
  }
}

variable "node_group_key_name" {
  description = "EC2 Key Pair name for node SSH access (must exist in AWS if provided)"
  type        = string
  default     = null
  
  validation {
    condition = var.node_group_key_name == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*$", var.node_group_key_name))
    error_message = "Key pair name must contain only alphanumeric characters, underscores, and hyphens, and must start with an alphanumeric character."
  }
}