provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = module.materialize_infrastructure.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.materialize_infrastructure.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.materialize_infrastructure.eks_cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.materialize_infrastructure.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.materialize_infrastructure.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.materialize_infrastructure.eks_cluster_name]
    }
  }
}

module "materialize_infrastructure" {
  # To pull this from GitHub, use the following:
  # source = "git::https://github.com/MaterializeInc/terraform-aws-materialize.git"
  source = "../../"

  providers = {
    aws        = aws
    kubernetes = kubernetes
    helm       = helm
  }

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
  node_group_instance_types                = ["r7gd.2xlarge"]
  node_group_desired_size                  = 1
  node_group_min_size                      = 1
  node_group_max_size                      = 2
  node_group_capacity_type                 = "ON_DEMAND"
  enable_cluster_creator_admin_permissions = true

  swap_enabled = var.swap_enabled

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

  # Certificates
  install_cert_manager           = var.install_cert_manager
  use_self_signed_cluster_issuer = var.use_self_signed_cluster_issuer

  # Enable and configure Materialize operator
  install_materialize_operator = true
  operator_version             = var.operator_version
  orchestratord_version        = var.orchestratord_version
  helm_values                  = var.helm_values

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

resource "random_password" "analytics_mz_system" {
  length  = 20
  special = true
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

variable "operator_version" {
  description = "Version of the Materialize operator to install"
  type        = string
  default     = null
}

variable "orchestratord_version" {
  description = "Version of the Materialize orchestrator to install"
  type        = string
  default     = null
}

variable "materialize_instances" {
  description = "List of Materialize instances to be created."
  type = list(object({
    name                              = string
    namespace                         = string
    database_name                     = string
    environmentd_version              = optional(string)
    cpu_request                       = string
    memory_request                    = string
    memory_limit                      = string
    create_database                   = optional(bool)
    create_nlb                        = optional(bool)
    internal_nlb                      = optional(bool)
    in_place_rollout                  = optional(bool, false)
    request_rollout                   = optional(string)
    force_rollout                     = optional(string)
    balancer_memory_request           = optional(string, "256Mi")
    balancer_memory_limit             = optional(string, "256Mi")
    balancer_cpu_request              = optional(string, "100m")
    license_key                       = optional(string)
    authenticator_kind                = optional(string, "None")
    external_login_password_mz_system = optional(string)
    environmentd_extra_args           = optional(list(string), [])
  }))
  default = []
}

variable "helm_values" {
  description = "Additional Helm values to merge with defaults"
  type        = any
  default     = {}
}

variable "install_cert_manager" {
  description = "Whether to install cert-manager."
  type        = bool
  default     = true
}

variable "use_self_signed_cluster_issuer" {
  description = "Whether to install and use a self-signed ClusterIssuer for TLS. To work around limitations in Terraform, this will be treated as `false` if no materialize instances are defined."
  type        = bool
  default     = true
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

output "cluster_certificate_authority_data" {
  description = "The CA certificate for the EKS cluster"
  value       = module.materialize_infrastructure.cluster_certificate_authority_data
  sensitive   = true
}

output "nlb_details" {
  description = "Details of the Materialize instance NLBs."
  value       = module.materialize_infrastructure.nlb_details
}
