variable "cluster_name" {
  description = "Name of the EKS cluster to attach the node group to."
  type        = string
  nullable    = false
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group."
  type        = list(string)
  nullable    = false
}

variable "node_group_name" {
  description = "Name of the node group."
  type        = string
  nullable    = false
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 1
  nullable    = false
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
  nullable    = false
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
  nullable    = false
}

variable "instance_types" {
  description = <<EOF
Instance types for worker nodes.

Recommended Configuration:
- For other workloads: `r7g`, `r6g` families (ARM-based Graviton, without local disks)
- For materialize instance workloads: `r6gd`, `r7gd` families (ARM-based Graviton, with local NVMe disks)
- Enable disk setup when using instance types with local storage
EOF
  type        = list(string)
  nullable    = false
}

variable "capacity_type" {
  description = "Capacity type for worker nodes (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "ami_type" {
  description = "AMI type for the node group."
  type        = string
  default     = "BOTTLEROCKET_ARM_64"
  nullable    = false
}

variable "labels" {
  description = "Labels to apply to the node group."
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Taints to apply to the node group."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "swap_enabled" {
  description = "Whether to enable swap on the local NVMe disks."
  type        = bool
  default     = true
  nullable    = false
}

variable "disk_setup_image" {
  description = "Docker image for the disk setup script"
  type        = string
  default     = "docker.io/materialize/ephemeral-storage-setup-image:v0.4.0"
  nullable    = false
}

variable "cluster_service_cidr" {
  description = "The CIDR block for the cluster service"
  type        = string
  nullable    = false
}

variable "cluster_primary_security_group_id" {
  description = "The ID of the primary security group for the cluster"
  type        = string
  nullable    = false
}

variable "iam_role_use_name_prefix" {
  description = "Use name prefix for IAM roles"
  type        = bool
  default     = true
}
