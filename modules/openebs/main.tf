# Create OpenEBS namespace
resource "kubernetes_namespace" "openebs" {
  count = var.install_openebs ? 1 : 0

  metadata {
    name = var.openebs_namespace
  }
}

# Install OpenEBS Helm chart for lgalloc support
resource "helm_release" "openebs" {
  count = var.install_openebs ? 1 : 0

  name       = "openebs"
  namespace  = kubernetes_namespace.openebs[0].metadata[0].name
  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = var.openebs_version

  set {
    name  = "engines.replicated.mayastor.enabled"
    value = "false"
  }

  depends_on = [kubernetes_namespace.openebs]
}
