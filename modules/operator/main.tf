locals {
  name_prefix = "${var.namespace}-${var.environment}"
}

resource "kubernetes_namespace" "materialize" {
  metadata {
    name = var.operator_namespace
  }
}

resource "kubernetes_namespace" "instance_namespaces" {
  for_each = toset(compact([for instance in var.instances : instance.namespace if instance.namespace != null]))

  metadata {
    name = each.key
  }
}

resource "helm_release" "materialize_operator" {
  name      = "${local.name_prefix}-operator"
  namespace = kubernetes_namespace.materialize.metadata[0].name
  # TODO: Publish the chart to a public repository, currently using a forked version of the chart
  repository = "https://raw.githubusercontent.com/bobbyiliev/materialize/refs/heads/helm-chart-package/misc/helm-charts"
  chart      = "materialize-operator"
  # version    = var.operator_version
  # TODO: Use the latest version of the chart
  version = "v25.1.0-beta.1"

  values = [
    yamlencode({
      operator = {
        cloudProvider = {
          type   = "aws"
          region = data.aws_region.current.name
          providers = {
            aws = {
              enabled   = true
              accountID = data.aws_caller_identity.current.account_id
              iam = {
                roles = {
                  environment = var.iam_role_arn
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.materialize]
}

resource "kubernetes_secret" "materialize_backends" {
  for_each = { for idx, instance in var.instances : instance.name => instance }

  metadata {
    name      = "${each.key}-materialize-backend"
    namespace = coalesce(each.value.namespace, var.operator_namespace)
  }

  data = {
    metadata_backend_url = format(
      "postgres://%s:%s@%s/%s?sslmode=require",
      each.value.database_username,
      each.value.database_password,
      each.value.database_host,
      coalesce(each.value.database_name, "${each.key}_db")
    )
    persist_backend_url = format(
      "s3://%s/%s-%s:serviceaccount:%s:%s",
      var.s3_bucket_name,
      var.environment,
      each.key,
      coalesce(each.value.namespace, kubernetes_namespace.materialize.metadata[0].name),
      each.value.instance_id
    )
  }
}

resource "kubernetes_manifest" "materialize_instances" {
  for_each = { for idx, instance in var.instances : instance.name => instance }

  manifest = {
    apiVersion = "materialize.cloud/v1alpha1"
    kind       = "Materialize"
    metadata = {
      name      = each.value.instance_id
      namespace = coalesce(each.value.namespace, var.operator_namespace)
    }
    spec = {
      environmentdImageRef = "materialize/environmentd:${var.operator_version}"
      backendSecretName    = "${each.key}-materialize-backend"
      environmentdResourceRequirements = {
        limits = {
          memory = each.value.memory_limit
        }
        requests = {
          cpu    = each.value.cpu_request
          memory = each.value.memory_request
        }
      }
      balancerdResourceRequirements = {
        limits = {
          memory = "256Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
      }
    }
  }

  depends_on = [
    helm_release.materialize_operator,
    kubernetes_secret.materialize_backends,
    kubernetes_namespace.instance_namespaces
  ]
}

# Materialize does not currently create databases within the instances, so we need to create them ourselves
resource "kubernetes_manifest" "db_init_configmap" {
  for_each = { for idx, instance in var.instances : instance.name => instance }

  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "init-db-script-${each.key}"
      namespace = coalesce(each.value.namespace, var.operator_namespace)
    }
    data = {
      "init.sql" = format(
        "CREATE DATABASE IF NOT EXISTS %s;",
        coalesce(each.value.database_name, "${each.key}_db")
      )
    }
  }
}

resource "kubernetes_manifest" "db_init_job" {
  for_each = { for idx, instance in var.instances : instance.name => instance }

  manifest = {
    apiVersion = "batch/v1"
    kind       = "Job"
    metadata = {
      name      = "create-db-${each.key}"
      namespace = coalesce(each.value.namespace, var.operator_namespace)
    }
    spec = {
      template = {
        spec = {
          containers = [{
            name  = "init-db"
            image = "postgres:${var.postgres_version}"
            command = [
              "/bin/sh",
              "-c",
              format(
                "psql $DATABASE_URL -c \"CREATE DATABASE %s;\"",
                coalesce(each.value.database_name, "${each.key}_db")
              )
            ]
            env = [
              {
                name = "DATABASE_URL"
                value = format(
                  "postgres://%s:%s@%s/%s?sslmode=require",
                  each.value.database_username,
                  each.value.database_password,
                  each.value.database_host,
                  "postgres" # Default database to connect to
                )
              }
            ]
          }]
          restartPolicy = "OnFailure"
        }
      }
      backoffLimit = 3
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
