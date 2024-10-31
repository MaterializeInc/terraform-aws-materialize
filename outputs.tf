output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
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
  value = format("postgres://%s:%s@%s/%s?sslmode=disable",
    var.database_username,
    var.database_password,
    module.database.db_instance_endpoint,
    var.database_name
  )
  sensitive = true
}

output "persist_backend_url" {
  description = "S3 connection URL in the format required by Materialize"
  value = format("s3://%s:%s@%s/%s?endpoint=https%%3A%%2F%%2Fs3.%s.amazonaws.com&region=%s",
    aws_iam_access_key.materialize_user.id,
    aws_iam_access_key.materialize_user.secret,
    var.bucket_name,
    var.environment,
    data.aws_region.current.name,
    data.aws_region.current.name
  )
  sensitive = true
}
