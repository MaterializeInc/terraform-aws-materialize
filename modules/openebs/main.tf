resource "kubernetes_namespace" "openebs" {
  count = var.create_openebs_namespace ? 1 : 0

  metadata {
    name = var.openebs_namespace
  }
}

resource "helm_release" "openebs" {
  name       = "openebs"
  namespace  = var.openebs_namespace
  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = var.openebs_version

  set {
    name  = "engines.replicated.mayastor.enabled"
    value = "false"
  }

  depends_on = [kubernetes_namespace.openebs]
}
