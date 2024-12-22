provider "aws" {
  region = "us-east-1"
}

module "materialize_infrastructure" {
  # To pull this from GitHub, use the following:
  # source = "git::https://github.com/MaterializeInc/terraform-aws-materialize.git"
  source = "../../"

  # The namespace and environment variables are used to construct the names of the resources
  # e.g. ${namespace}-${environment}-storage, ${namespace}-${environment}-db etc.
  namespace   = "simple-mz-tf"
  environment = "dev"

  # VPC Configuration
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
  single_nat_gateway   = true

  # EKS Configuration
  cluster_version = "1.31"
  # node_group_instance_types                = ["m6g.medium"]
  # TODO: Defaulting to a smaller instance type due to resource constraints
  node_group_instance_types                = ["r5.xlarge"]
  node_group_desired_size                  = 2
  node_group_min_size                      = 1
  node_group_max_size                      = 3
  node_group_capacity_type                 = "ON_DEMAND"
  enable_cluster_creator_admin_permissions = true

  # Storage Configuration
  enable_bucket_versioning = true
  enable_bucket_encryption = true
  bucket_force_destroy     = true

  # Database Configuration
  database_password    = var.database_password
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

  # Configure Materialize instances
  materialize_instances = [
    {
      name              = "analytics"
      instance_id       = "12345678-1234-1234-1234-123456789012"
      namespace         = "materialize-environment"
      database_name     = "analytics_db"
      database_username = "materialize"
      database_password = var.database_password
      database_host     = module.materialize_infrastructure.database_endpoint
    },
    {
      name              = "production"
      instance_id       = "87654321-4321-4321-4321-210987654321"
      namespace         = "materialize-environment"
      database_name     = "production_db"
      database_username = "materialize"
      database_password = var.database_password
      database_host     = module.materialize_infrastructure.database_endpoint
    }
  ]

  # Tags
  tags = {
    Environment = "dev"
    Project     = "materialize-simple"
    Terraform   = "true"
  }
}

variable "database_password" {
  description = "Password for the database (should be provided via tfvars or environment variable)"
  default     = "your-secure-password"
  type        = string
  sensitive   = true
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
