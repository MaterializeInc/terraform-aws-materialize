output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_endpoint
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.storage.bucket_name
}

output "metadata_backend_url" {
  description = "PostgreSQL connection URL in the format required by Materialize"
  value = format("postgres://%s:%s@%s/%s?sslmode=require&options=-c%%20statement_timeout%%3D%s",
    var.database_username,
    var.database_password,
    module.database.db_instance_endpoint,
    var.database_name,
    var.database_statement_timeout
  )
  sensitive = true
}

output "persist_backend_url" {
  description = "S3 connection URL in the format required by Materialize using IRSA"
  value = format("s3://%s/%s:serviceaccount:%s:%s",
    module.storage.bucket_name,
    var.environment,
    var.kubernetes_namespace,
    var.service_account_name
  )
}

# oidc_provider_arn
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

# aws_iam_role.materialize_s3.arn
output "materialize_s3_role_arn" {
  description = "The ARN of the IAM role for Materialize"
  value       = aws_iam_role.materialize_s3.arn
}

output "operator_details" {
  description = "Details of the installed Materialize operator"
  value = var.install_materialize_operator ? {
    namespace             = module.operator[0].operator_namespace
    release_name          = module.operator[0].operator_release_name
    release_status        = module.operator[0].operator_release_status
    instances             = module.operator[0].materialize_instances
    instance_resource_ids = module.operator[0].materialize_instance_resource_ids
  } : null
}

output "nlb_details" {
  description = "Details of the Materialize instance NLBs."
  value = {
    for nlb in module.nlb : nlb.instance_name => {
      arn      = nlb.nlb_arn
      dns_name = nlb.nlb_dns_name
    }
  }
}
