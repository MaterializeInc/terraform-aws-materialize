output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "materialize_operator_namespace" {
  description = "Namespace where the Materialize operator is installed"
  value       = module.operator.operator_namespace
}

output "metadata_backend_url" {
  description = "Metadata backend URL"
  value       = local.metadata_backend_url
  sensitive   = true
}

output "persist_backend_url" {
  description = "Persist backend URL"
  value       = local.persist_backend_url
}
