output "cluster_issuer_name" {
  description = "Name of the ClusterIssuer"
  value       = var.use_self_signed_cluster_issuer ? kubernetes_manifest.root_ca_cluster_issuer[0].object.metadata.name : null
}
