variable "namespace" {
  description = "Namespace to install the AWS LBC"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account used by the AWS LBC"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "iam_name" {
  description = "Name of the AWS IAM role and policy"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster OIDC provider"
  type        = string
}

variable "oidc_issuer_url" {
  description = "URL of the EKS cluster OIDC issuer"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "region" {
  description = "AWS region of the VPC"
  type        = string
}
