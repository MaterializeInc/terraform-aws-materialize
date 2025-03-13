output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
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
  value = format("postgres://%s:%s@%s/%s?sslmode=require",
    var.database_username,
    var.database_password,
    module.database.db_instance_endpoint,
    var.database_name
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

# aws_iam_role.materialize_s3.arn
output "materialize_s3_role_arn" {
  description = "The ARN of the IAM role for Materialize"
  value       = aws_iam_role.materialize_s3.arn
}
