output "openebs_namespace" {
  description = "Namespace where OpenEBS is installed"
  value       = var.install_openebs ? var.openebs_namespace : ""
}
