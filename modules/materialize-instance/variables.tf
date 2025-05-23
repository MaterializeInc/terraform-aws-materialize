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

# Database configuration
variable "create_database" {
  description = "Whether to create a dedicated RDS instance for this Materialize instance"
  type        = bool
  default     = true
}

variable "existing_metadata_backend_url" {
  description = "Existing metadata backend URL for the Materialize instance. Only used if create_database is false"
  type        = string
  default     = ""
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "database_username" {
  description = "Username for the database"
  type        = string
  default     = "materialize"
}

variable "database_password" {
  description = "Password for the database (should be provided via tfvars or environment variable)"
  type        = string
  sensitive   = true
}

variable "postgres_version" {
  description = "Version of PostgreSQL to use"
  type        = string
  default     = "15"
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.large"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling (in GB)"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# Storage configuration
variable "create_storage" {
  description = "Whether to create a dedicated S3 bucket for this Materialize instance"
  type        = bool
  default     = true
}

variable "existing_persist_backend_url" {
  description = "Existing persist backend URL for the Materialize instance. Only used if create_storage is false"
  type        = string
  default     = ""
}

variable "existing_bucket_arn" {
  description = "ARN of an existing S3 bucket to use. Only used if create_storage is false but IAM roles are still created"
  type        = string
  default     = ""
}

variable "bucket_force_destroy" {
  description = "Enable force destroy for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_bucket_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_bucket_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "bucket_lifecycle_rules" {
  description = "List of lifecycle rules for the S3 bucket"
  type = list(object({
    id                                 = string
    enabled                            = bool
    prefix                             = string
    transition_days                    = number
    transition_storage_class           = string
    noncurrent_version_expiration_days = number
  }))
  default = [{
    id                                 = "cleanup"
    enabled                            = true
    prefix                             = ""
    transition_days                    = 90
    transition_storage_class           = "STANDARD_IA"
    noncurrent_version_expiration_days = 90
  }]
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
