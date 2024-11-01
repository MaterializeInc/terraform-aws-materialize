# General Variables
variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "materialize"
  }
}

# Networking Variables
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "materialize-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

# EKS Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "materialize-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_group_instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for worker nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "cluster_enabled_log_types" {
  description = "List of desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# RDS Variables
variable "db_identifier" {
  description = "Identifier for the RDS instance"
  type        = string
  default     = "materialize-db"
}

variable "postgres_version" {
  description = "Version of PostgreSQL to use"
  type        = string
  default     = "15"
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.medium"
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

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "materialize"
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

variable "db_multi_az" {
  description = "Enable multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# S3 Variables
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "bucket_force_destroy" {
  description = "Enable force destroy for the S3 bucket"
  type        = bool
  default     = false
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
    expiration_days                    = number
    noncurrent_version_expiration_days = number
  }))
  default = [{
    id                                 = "cleanup"
    enabled                            = true
    prefix                             = ""
    transition_days                    = 90
    transition_storage_class           = "STANDARD_IA"
    expiration_days                    = 365
    noncurrent_version_expiration_days = 90
  }]
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "metrics_retention_days" {
  description = "Number of days to retain CloudWatch metrics"
  type        = number
  default     = 7
}

variable "namespace" {
  description = "Namespace for Materialize resources"
  type        = string
  default     = "materialize-environment"
}

variable "service_account_name" {
  description = "Name of the service account"
  type        = string
  default     = "12345678-1234-1234-1234-123456789012"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket"
  type        = string
  default     = "system"
}
