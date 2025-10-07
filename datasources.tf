data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "utils_deep_merge_yaml" "helm_values" {
  input = [
    yamlencode(local.default_helm_values),
    yamlencode(var.helm_values)
  ]
}
