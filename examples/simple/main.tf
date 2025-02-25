provider "aws" {
  region = "us-east-1"
}

module "materialize_infrastructure" {
  # To pull this from GitHub, use the following:
  # source = "git::https://github.com/MaterializeInc/terraform-aws-materialize.git"
  source = "../../"

  # The namespace and environment variables are used to construct the names of the resources
  # e.g. ${namespace}-${environment}-storage, ${namespace}-${environment}-db etc.
  namespace   = var.namespace
  environment = var.environment

  # VPC Configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
  single_nat_gateway   = true

  # EKS Configuration
  cluster_version                          = "1.32"
  node_group_instance_types                = ["r8g.2xlarge"]
  node_group_desired_size                  = 1
  node_group_min_size                      = 1
  node_group_max_size                      = 2
  node_group_capacity_type                 = "ON_DEMAND"
  enable_cluster_creator_admin_permissions = true

  # Storage Configuration
  bucket_force_destroy = true

  # For testing purposes, we are disabling encryption and versioning to allow for easier cleanup
  # This should be enabled in production environments for security and data integrity
  enable_bucket_versioning = false
  enable_bucket_encryption = false

  # Database Configuration
  database_password    = random_password.pass.result
  postgres_version     = "15"
  db_instance_class    = "db.t3.large"
  db_allocated_storage = 20
  database_name        = "materialize"
  database_username    = "materialize"
  db_multi_az          = false

  # Basic monitoring
  enable_monitoring      = true
  metrics_retention_days = 3

  # Enable and configure Materialize operator
  install_materialize_operator = true

  # Once the operator is installed, you can define your Materialize instances here.
  materialize_instances = var.materialize_instances

  # Tags
  tags = {
    Environment = "dev"
    Project     = "materialize-simple"
    Terraform   = "true"
  }
}

resource "random_password" "pass" {
  length  = 20
  special = false
}

variable "namespace" {
  description = "Namespace for the resources. Used to prefix the names of the resources"
  type        = string
  default     = "simple-mz-tf"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "materialize_instances" {
  description = "List of Materialize instances to be created."
  type = list(object({
    name            = string
    namespace       = string
    database_name   = string
    cpu_request     = string
    memory_request  = string
    memory_limit    = string
    create_database = optional(bool)
  }))
  default = []
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.materialize_infrastructure.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.materialize_infrastructure.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.materialize_infrastructure.eks_cluster_name
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.materialize_infrastructure.database_endpoint
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.materialize_infrastructure.s3_bucket_name
}

output "metadata_backend_url" {
  description = "PostgreSQL connection URL in the format required by Materialize"
  value       = module.materialize_infrastructure.metadata_backend_url
  sensitive   = true
}

output "persist_backend_url" {
  description = "S3 connection URL in the format required by Materialize using IRSA"
  value       = module.materialize_infrastructure.persist_backend_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.materialize_infrastructure.oidc_provider_arn
}

output "materialize_s3_role_arn" {
  description = "The ARN of the IAM role for Materialize"
  value       = module.materialize_infrastructure.materialize_s3_role_arn
}
