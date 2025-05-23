# General
variable "name_prefix" {
  description = "Prefix for all resource names (replaces separate namespace and environment variables)"
  type        = string
}

variable "instance_name" {
  description = "Name of the Materialize instance"
  type        = string
}

variable "instance_namespace" {
  description = "Kubernetes namespace for the Materialize instance. If not provided, it will use the operator_namespace"
  type        = string
  default     = null
}

variable "operator_namespace" {
  description = "Namespace where the Materialize operator is installed"
  type        = string
  default     = "materialize"
}

variable "create_namespace" {
  description = "Whether to create a dedicated Kubernetes namespace for the Materialize instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Infrastructure references
variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where resources will be created"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for public-facing resources"
  type        = list(string)
  default     = []
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

variable "eks_node_security_group_id" {
  description = "Security group ID of the EKS node group"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  type        = string
}

# IAM configuration
variable "create_iam_role" {
  description = "Whether to create a dedicated IAM role for this Materialize instance"
  type        = bool
  default     = true
}

# NLB configuration
variable "create_nlb" {
  description = "Whether to create a dedicated NLB for this Materialize instance"
  type        = bool
  default     = true
}

variable "internal_nlb" {
  description = "Whether the NLB should be internal"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing for the NLB"
  type        = bool
  default     = true
}

# Materialize instance configuration
variable "environmentd_version" {
  description = "Version of the Materialize environmentd to use"
  type        = string
  default     = "v0.130.13" # Default version
}

variable "environmentd_extra_env" {
  description = "Extra environment variables for environmentd"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "environmentd_extra_args" {
  description = "Extra arguments for environmentd"
  type        = list(string)
  default     = []
}

variable "cpu_request" {
  description = "CPU request for the environmentd container"
  type        = string
  default     = "1"
}

variable "memory_request" {
  description = "Memory request for the environmentd container"
  type        = string
  default     = "1Gi"
}

variable "memory_limit" {
  description = "Memory limit for the environmentd container"
  type        = string
  default     = "1Gi"
}

variable "balancer_cpu_request" {
  description = "CPU request for the balancerd container"
  type        = string
  default     = "100m"
}

variable "balancer_memory_request" {
  description = "Memory request for the balancerd container"
  type        = string
  default     = "256Mi"
}

variable "balancer_memory_limit" {
  description = "Memory limit for the balancerd container"
  type        = string
  default     = "256Mi"
}

variable "in_place_rollout" {
  description = "Whether to perform in-place rollout for the Materialize instance"
  type        = bool
  default     = false
}

variable "request_rollout" {
  description = "Rollout request ID in UUID format for the Materialize instance"
  type        = string
  default     = null
}

variable "force_rollout" {
  description = "Force rollout ID in UUID format for the Materialize instance"
  type        = string
  default     = null
}

variable "license_key" {
  description = "License key for the Materialize instance"
  type        = string
  default     = null
  sensitive   = true
}

variable "use_self_signed_cluster_issuer" {
  description = "Whether to use a self-signed cluster issuer for cert-manager"
  type        = bool
  default     = true
}

variable "metadata_backend_url" {
  description = "The full connection URL for the metadata backend (Postgres)."
  type        = string
}

variable "persist_backend_url" {
  description = "The full connection URL for the persist backend (S3)."
  type        = string
}
