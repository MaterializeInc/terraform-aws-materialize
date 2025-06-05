variable "instance_name" {
  description = "Name of the Materialize instance"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace. Set to false if the namespace already exists."
  type        = bool
  default     = true
}

variable "instance_namespace" {
  description = "Kubernetes namespace for the instance."
  type        = string
}

variable "metadata_backend_url" {
  description = "PostgreSQL connection URL for metadata backend"
  type        = string
  sensitive   = true
}

variable "persist_backend_url" {
  description = "S3 connection URL for persist backend"
  type        = string
}

variable "license_key" {
  description = "Materialize license key"
  type        = string
  default     = null
  sensitive   = true
}

# Environmentd Configuration
variable "environmentd_version" {
  description = "Version of environmentd to use"
  type        = string
  default     = "v0.130.13" # META: mz version
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
  description = "Extra command line arguments for environmentd"
  type        = list(string)
  default     = []
}

# Resource Requirements
variable "cpu_request" {
  description = "CPU request for environmentd"
  type        = string
  default     = "1"
}

variable "memory_request" {
  description = "Memory request for environmentd"
  type        = string
  default     = "1Gi"
}

variable "memory_limit" {
  description = "Memory limit for environmentd"
  type        = string
  default     = "1Gi"
}

# Rollout Configuration
variable "in_place_rollout" {
  description = "Whether to perform in-place rollouts"
  type        = bool
  default     = true
}

variable "request_rollout" {
  description = "UUID to request a rollout"
  type        = string
  default     = "00000000-0000-0000-0000-000000000001"

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.request_rollout))
    error_message = "Request rollout must be a valid UUID in the format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}

variable "force_rollout" {
  description = "UUID to force a rollout"
  type        = string
  default     = "00000000-0000-0000-0000-000000000001"

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.force_rollout))
    error_message = "Force rollout must be a valid UUID in the format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}

# Balancer Resource Requirements
variable "balancer_memory_request" {
  description = "Memory request for balancer"
  type        = string
  default     = "256Mi"
}

variable "balancer_memory_limit" {
  description = "Memory limit for balancer"
  type        = string
  default     = "256Mi"
}

variable "balancer_cpu_request" {
  description = "CPU request for balancer"
  type        = string
  default     = "100m"
}
