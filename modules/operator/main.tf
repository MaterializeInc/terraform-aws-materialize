resource "kubernetes_namespace" "materialize" {
  metadata {
    name = var.operator_namespace
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

locals {
  default_helm_values = {
    observability = {
      podMetrics = {
        enabled = true
      }
    }
    operator = {
      image = var.orchestratord_version == null ? {} : {
        tag = var.orchestratord_version
      },
      cloudProvider = {
        type   = "aws"
        region = var.aws_region
        providers = {
          aws = {
            enabled   = true
            accountID = var.aws_account_id
            iam = {
              roles = {
                environment = aws_iam_role.materialize_s3.arn
              }
            }
          }
        }
      }
    }
    storage = var.enable_disk_support ? {
      storageClass = {
        create      = local.disk_config.create_storage_class
        name        = local.disk_config.storage_class_name
        provisioner = local.disk_config.storage_class_provisioner
        parameters  = local.disk_config.storage_class_parameters
      }
    } : {}
    tls = var.use_self_signed_cluster_issuer ? {
      defaultCertificateSpecs = {
        balancerdExternal = {
          dnsNames = [
            "balancerd",
          ]
          issuerRef = {
            name = "${var.name_prefix}-root-ca"
            kind = "ClusterIssuer"
          }
        }
        consoleExternal = {
          dnsNames = [
            "console",
          ]
          issuerRef = {
            name = "${var.name_prefix}-root-ca"
            kind = "ClusterIssuer"
          }
        }
        internal = {
          issuerRef = {
            name = "${var.name_prefix}-root-ca"
            kind = "ClusterIssuer"
          }
        }
      }
    } : {}
  }

  # Requires OpenEBS to be installed
  disk_config = {
    run_disk_setup_script     = var.enable_disk_support ? lookup(var.disk_support_config, "run_disk_setup_script", true) : false
    local_ssd_count           = lookup(var.disk_support_config, "local_ssd_count", 1)
    create_storage_class      = var.enable_disk_support ? lookup(var.disk_support_config, "create_storage_class", true) : false
    openebs_version           = lookup(var.disk_support_config, "openebs_version", "4.2.0")
    openebs_namespace         = lookup(var.disk_support_config, "openebs_namespace", "openebs")
    storage_class_name        = lookup(var.disk_support_config, "storage_class_name", "openebs-lvm-instance-store-ext4")
    storage_class_provisioner = "local.csi.openebs.io"
    storage_class_parameters = {
      storage  = "lvm"
      fsType   = "ext4"
      volgroup = "instance-store-vg"
    }
  }
}

resource "helm_release" "materialize_operator" {
  name      = var.name_prefix
  namespace = kubernetes_namespace.materialize.metadata[0].name

  repository = var.use_local_chart ? null : var.helm_repository
  chart      = var.helm_chart
  version    = var.use_local_chart ? null : var.operator_version

  values = [
    yamlencode(merge(local.default_helm_values, var.helm_values))
  ]

  depends_on = [kubernetes_namespace.materialize]
}

# Install the metrics-server for monitoring
# Required for the Materialize Console to display cluster metrics
resource "helm_release" "metrics_server" {
  count = var.install_metrics_server ? 1 : 0

  name       = "${var.name_prefix}-metrics-server"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version

  # Common configuration values
  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

resource "aws_iam_role" "materialize_s3" {
  name = "${var.name_prefix}-mz-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${trimprefix(var.cluster_oidc_issuer_url, "https://")}:sub" : "system:serviceaccount:*:*",
            "${trimprefix(var.cluster_oidc_issuer_url, "https://")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "${var.name_prefix}-mz-role"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy" "materialize_s3" {
  name = "${var.name_prefix}-mz-role-policy"
  role = aws_iam_role.materialize_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn != null ? var.s3_bucket_arn : "*",
          var.s3_bucket_arn != null ? "${var.s3_bucket_arn}/*" : "*"
        ]
      }
    ]
  })
}
