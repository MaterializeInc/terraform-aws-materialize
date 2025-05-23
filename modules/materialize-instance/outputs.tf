output "instance_name" {
  description = "Name of the Materialize instance"
  value       = var.instance_name
}

output "instance_namespace" {
  description = "Namespace of the Materialize instance"
  value       = local.instance_namespace
}

output "instance_resource_id" {
  description = "Resource ID of the Materialize instance"
  value       = data.kubernetes_resource.materialize_instance.object.status.resourceId
}

output "database_name" {
  description = "Name of the database"
  value       = var.database_name
}

output "database_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = var.create_database ? module.database[0].db_instance_endpoint : null
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = var.create_storage ? module.storage[0].bucket_name : null
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = var.create_storage ? module.storage[0].bucket_arn : null
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = var.create_iam_role ? aws_iam_role.materialize_instance[0].arn : null
}

output "nlb_arn" {
  description = "ARN of the NLB"
  value       = var.create_nlb ? module.nlb[0].nlb_arn : null
}

output "nlb_dns_name" {
  description = "DNS name of the NLB"
  value       = var.create_nlb ? module.nlb[0].nlb_dns_name : null
}

output "metadata_backend_url" {
  description = "Metadata backend URL used by the Materialize instance"
  value = var.create_database ? format(
    "postgres://%s:%s@%s/%s?sslmode=require",
    var.database_username,
    var.database_password,
    module.database[0].db_instance_endpoint,
    var.database_name
  ) : var.existing_metadata_backend_url
  sensitive = true
}

output "persist_backend_url" {
  description = "Persist backend URL used by the Materialize instance"
  value = var.create_storage ? format(
    "s3://%s/%s-%s:serviceaccount:%s:%s",
    module.storage[0].bucket_name,
    var.name_prefix,
    var.instance_name,
    local.instance_namespace,
    var.instance_name
  ) : var.existing_persist_backend_url
}

output "cluster_issuer_name" {
  description = "Name of the ClusterIssuer"
  value       = var.use_self_signed_cluster_issuer ? kubernetes_manifest.root_ca_cluster_issuer[0].object.metadata.name : null
}
