variable "name_prefix" {
  description = "Prefix for all resource names (replaces separate namespace and environment variables)"
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
  default     = "AL2023_x86_64_STANDARD"
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

variable "enable_disk_setup" {
  description = "Whether to enable disk setup using the bootstrap script"
  type        = bool
  default     = true
}
