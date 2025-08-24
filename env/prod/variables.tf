variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-prod"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.4.0.0/16"
}


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

variable "enable_prefix_delegation" {
  description = "Enable prefix delegation for increased pod density"
  type        = bool
  default     = true
}

variable "enable_kms_encryption" {
  description = "Enable KMS encryption for EKS secrets"
  type        = bool
  default     = true
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
  default     = ["m5.large", "m5.xlarge"]
}

variable "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 10
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_group_key_name" {
  description = "EC2 Key Pair name for node SSH access"
  type        = string
  default     = null
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}