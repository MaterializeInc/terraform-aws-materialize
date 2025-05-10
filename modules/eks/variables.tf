variable "namespace" {
  description = "Namespace prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where EKS will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS"
  type        = list(string)
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "node_group_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
}

variable "node_group_ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
}

variable "cluster_enabled_log_types" {
  description = "List of desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "node_group_capacity_type" {
  description = "Capacity type for worker nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "enable_cluster_creator_admin_permissions" {
  description = "To add the current caller identity as an administrator"
  type        = bool
  default     = true
}

# OpenEBS configuration
variable "install_openebs" {
  description = "Whether to install OpenEBS for NVMe storage"
  type        = bool
  default     = true
}

variable "openebs_namespace" {
  description = "Namespace for OpenEBS components"
  type        = string
  default     = "openebs"
}

variable "openebs_version" {
  description = "Version of OpenEBS Helm chart to install"
  type        = string
  default     = "4.2.0"
}

variable "enable_disk_setup" {
  description = "Whether to enable disk setup using the bootstrap script"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR of eks vpc"
  type        = string
}

variable "cluster_service_ipv4_cidr" {
  description = "CIDR block to assign Kubernetes service IP addresses from"
  type        = string
  default     = "10.100.0.0/16"
}

# Karpenter configuration
variable "install_karpenter" {
  description = "Whether to install Karpenter"
  type        = bool
  default     = false
}

variable "karpenter_version" {
  description = "Version of the Karpenter Helm chart to install"
  type        = string
  default     = "1.3.3"
}

variable "karpenter_namespace" {
  description = "Namespace for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "karpenter_service_account" {
  description = "Name of the Karpenter service account"
  type        = string
  default     = "karpenter"
}

variable "karpenter_settings" {
  description = "Additional settings for Karpenter Helm chart"
  type        = map(string)
  default     = {}
}

variable "karpenter_instance_sizes" {
  description = "Additional settings for Karpenter Helm chart"
  type        = list(string)
  default = [
    "r7gd.xlarge",
    "r7gd.2xlarge",
    "r7gd.4xlarge",
    "r7gd.8xlarge",
  ]
}

variable "region" {
  description = "AWS region"
  type        = string
}
