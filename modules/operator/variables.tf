variable "namespace" {
  description = "Namespace prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "operator_version" {
  description = "Version of the Materialize operator to install"
  type        = string
  default     = "v0.127.1"
}

variable "iam_role_arn" {
  description = "IAM role ARN for Materialize S3 access"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for Materialize storage"
  type        = string
}

variable "operator_namespace" {
  description = "Namespace for the Materialize operator"
  type        = string
  default     = "materialize"
}

variable "instances" {
  description = "Configuration for Materialize instances"
  type = list(object({
    name              = string
    instance_id       = string
    namespace         = optional(string, "materialize-environment")
    database_name     = string
    database_username = string
    database_password = string
    database_host     = string
    cpu_request       = optional(string, "1")
    memory_request    = optional(string, "1Gi")
    memory_limit      = optional(string, "1Gi")
  }))
  default = []
}
