variable "cluster_name" {
  description = "Name of the EKS cluster to attach the node group to."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group."
  type        = list(string)
}

variable "node_group_name" {
  description = "Name of the node group."
  type        = string
}

variable "desired_size" {
  description = "Desired number of worker nodes."
  type        = number
}

variable "min_size" {
  description = "Minimum number of worker nodes."
  type        = number
}

variable "max_size" {
  description = "Maximum number of worker nodes."
  type        = number
}

variable "instance_types" {
  description = "List of instance types for the node group."
  type        = list(string)
}

variable "capacity_type" {
  description = "Capacity type for worker nodes (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

variable "ami_type" {
  description = "AMI type for the node group."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "labels" {
  description = "Labels to apply to the node group."
  type        = map(string)
  default     = {}
}

variable "enable_disk_setup" {
  description = "Whether to enable disk setup using the bootstrap script"
  type        = bool
  default     = true
}

variable "cluster_service_cidr" {
  description = "The CIDR block for the cluster service"
  type        = string
}

variable "cluster_primary_security_group_id" {
  description = "The ID of the primary security group for the cluster"
  type        = string
}
