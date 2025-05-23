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
  value       = var.metadata_backend_url
}

output "persist_backend_url" {
  description = "Persist backend URL used by the Materialize instance"
  value       = var.persist_backend_url
}
