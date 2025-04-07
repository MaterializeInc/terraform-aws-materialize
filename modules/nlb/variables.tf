variable "instance_name" {
  description = "The name of the Materialize instance."
  type        = string
}

variable "name_prefix" {
  description = "Prefix to use for NLB, Target Groups, Listeners, and TargetGroupBindings"
  type        = string
}

variable "internal" {
  description = "Whether the NLB is an internal only NLB."
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace in which to install TargetGroupBindings"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs in which to install the NLB. Must be in the VPC."
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "mz_resource_id" {
  description = "The resourceId from the Materialize CR"
  type        = string
}

variable "enable_cross_zone_load_balancing" {
  description = "Whether to enable cross zone load balancing on the NLB."
  type        = bool
  default     = true
}
