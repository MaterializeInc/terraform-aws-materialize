variable "aws_region" {
  description = "The AWS region where the resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "A prefix to add to all resource names."
  type        = string
  default     = "mz-demo"
}

variable "use_self_signed_cluster_issuer" {
  description = "Whether to use a self-signed ClusterIssuer for TLS certificates."
  type        = bool
  default     = true
}
