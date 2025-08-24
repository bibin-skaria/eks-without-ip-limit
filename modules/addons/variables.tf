variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
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

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "enable_ebs_csi" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "enable_cni_custom_networking" {
  description = "Enable AWS VPC CNI custom networking (disabled for stability)"
  type        = bool
  default     = false
}

variable "enable_prefix_delegation" {
  description = "Enable prefix delegation for increased pod density"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC Provider for IRSA"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "pod_subnet_ids" {
  description = "List of pod subnet IDs for custom networking"
  type        = list(string)
  default     = []
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}