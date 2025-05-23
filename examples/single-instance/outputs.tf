output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "materialize_operator_namespace" {
  description = "Namespace where the Materialize operator is installed"
  value       = module.operator.operator_namespace
}
