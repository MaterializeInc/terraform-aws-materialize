output "instance_name" {
  description = "Name of the Materialize instance"
  value       = var.instance_name
}

output "instance_namespace" {
  description = "Namespace of the Materialize instance"
  value       = var.instance_namespace
}

output "instance_resource_id" {
  description = "Resource ID of the Materialize instance"
  value       = data.kubernetes_resource.materialize_instance.object.status.resourceId
}

output "metadata_backend_url" {
  description = "Metadata backend URL used by the Materialize instance"
  value       = var.metadata_backend_url
}

output "persist_backend_url" {
  description = "Persist backend URL used by the Materialize instance"
  value       = var.persist_backend_url
}
