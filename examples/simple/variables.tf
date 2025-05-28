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

variable "install_materialize_instance" {
  description = "Whether to install the Materialize instance. Default is false as it requires the Kubernetes cluster to be created first."
  type        = bool
  default     = false
}

variable "create_nlb" {
  description = "Whether to create a Network Load Balancer for the Materialize instance"
  type        = bool
  default     = true
}

variable "internal_nlb" {
  description = "Whether the NLB should be internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "kubernetes_namespace" {
  description = "The Kubernetes namespace for the Materialize resources"
  type        = string
  default     = "materialize-environment"
}

variable "service_account_name" {
  description = "Name of the service account"
  type        = string
  default     = "12345678-1234-1234-1234-123456789012"
}
