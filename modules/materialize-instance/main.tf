# Create a namespace for this Materialize instance
resource "kubernetes_namespace" "instance" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.instance_namespace
  }
}

# Create the Materialize instance using the kubernetes_manifest resource
resource "kubernetes_manifest" "materialize_instance" {
  field_manager {
    # force field manager conflicts to be overridden
    name            = "terraform"
    force_conflicts = true
  }

  manifest = {
    apiVersion = "materialize.cloud/v1alpha1"
    kind       = "Materialize"
    metadata = {
      name      = var.instance_name
      namespace = var.instance_namespace
    }
    spec = {
      environmentdImageRef = "materialize/environmentd:${var.environmentd_version}"
      backendSecretName    = "${var.instance_name}-materialize-backend"
      inPlaceRollout       = var.in_place_rollout
      requestRollout       = var.request_rollout
      forceRollout         = var.force_rollout

      environmentdExtraEnv = length(var.environmentd_extra_env) > 0 ? [{
        name = "MZ_SYSTEM_PARAMETER_DEFAULT"
        value = join(";", [
          for item in var.environmentd_extra_env :
          "${item.name}=${item.value}"
        ])
      }] : null

      environmentdExtraArgs = length(var.environmentd_extra_args) > 0 ? var.environmentd_extra_args : null

      environmentdResourceRequirements = {
        limits = {
          memory = var.memory_limit
        }
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
      }
      balancerdResourceRequirements = {
        limits = {
          memory = var.balancer_memory_limit
        }
        requests = {
          cpu    = var.balancer_cpu_request
          memory = var.balancer_memory_request
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret.materialize_backend,
    kubernetes_namespace.instance,
  ]
}

# Create a secret with connection information for the Materialize instance
resource "kubernetes_secret" "materialize_backend" {
  metadata {
    name      = "${var.instance_name}-materialize-backend"
    namespace = var.instance_namespace
  }

  data = {
    metadata_backend_url = var.metadata_backend_url
    persist_backend_url  = var.persist_backend_url
    license_key          = var.license_key == null ? "" : var.license_key
  }

  depends_on = [
    kubernetes_namespace.instance
  ]
}

# Retrieve the resource ID of the Materialize instance
data "kubernetes_resource" "materialize_instance" {
  api_version = "materialize.cloud/v1alpha1"
  kind        = "Materialize"
  metadata {
    name      = var.instance_name
    namespace = var.instance_namespace
  }

  depends_on = [
    kubernetes_manifest.materialize_instance
  ]
}
