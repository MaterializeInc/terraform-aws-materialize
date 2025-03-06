variable "name" {
  description = "Name for Target Groups and TargetGroupBindings"
  type        = string
}

variable "nlb_arn" {
  description = "ARN of the NLB"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace in which to install TargetGroupBindings"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "port" {
  description = "Port for the NLB listener and Kubernetes service"
  type        = number
}

variable "health_check_path" {
  description = "The URL path for target group health checks"
  type        = string
}

variable "service_name" {
  description = "The name of the Kubernetes service to connect to"
  type        = string
}
