variable "name_prefix" {
  description = "Prefix for all resource names (replaces separate namespace and environment variables)"
  type        = string
}

variable "postgres_version" {
  description = "Version of PostgreSQL to use"
  type        = string
}

variable "instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (in GB)"
  type        = number
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "database_username" {
  description = "Username for the database"
  type        = string
}

variable "database_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the database"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster"
  type        = string
}

variable "eks_node_security_group_id" {
  description = "Security group ID of the EKS nodes"
  type        = string
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-06:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
