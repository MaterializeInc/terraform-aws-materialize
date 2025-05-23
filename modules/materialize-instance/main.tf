locals {
  instance_namespace = var.instance_namespace != null ? var.instance_namespace : var.operator_namespace
}

# Create a dedicated database for this instance
module "database" {
  source = "../database"
  count  = var.create_database ? 1 : 0

  name_prefix = var.name_prefix

  postgres_version           = var.postgres_version
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  database_name              = var.database_name
  database_username          = var.database_username
  multi_az                   = var.db_multi_az
  database_subnet_ids        = var.private_subnet_ids
  vpc_id                     = var.vpc_id
  eks_security_group_id      = var.eks_security_group_id
  eks_node_security_group_id = var.eks_node_security_group_id
  max_allocated_storage      = var.db_max_allocated_storage
  database_password          = var.database_password

  tags = var.tags
}

# Create a dedicated S3 bucket for this instance
module "storage" {
  source = "../storage"
  count  = var.create_storage ? 1 : 0

  name_prefix = "${var.name_prefix}-${var.instance_name}"

  bucket_lifecycle_rules   = var.bucket_lifecycle_rules
  enable_bucket_encryption = var.enable_bucket_encryption
  enable_bucket_versioning = var.enable_bucket_versioning
  bucket_force_destroy     = var.bucket_force_destroy

  tags = var.tags
}

# Create a dedicated IAM role for this instance
resource "aws_iam_role" "materialize_instance" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.name_prefix}-role"

  # Trust policy allowing EKS to assume this role
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
            "${trimprefix(var.cluster_oidc_issuer_url, "https://")}:sub" : "system:serviceaccount:${local.instance_namespace}:${var.instance_name}",
            "${trimprefix(var.cluster_oidc_issuer_url, "https://")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "materialize_instance" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.name_prefix}-policy"
  role = aws_iam_role.materialize_instance[0].id

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
        Resource = var.create_storage ? [
          module.storage[0].bucket_arn,
          "${module.storage[0].bucket_arn}/*"
          ] : [
          var.existing_bucket_arn,
          "${var.existing_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Create a namespace for this Materialize instance
resource "kubernetes_namespace" "instance" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = local.instance_namespace
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
      namespace = local.instance_namespace
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
    namespace = local.instance_namespace
  }

  data = {
    metadata_backend_url = var.create_database ? format(
      "postgres://%s:%s@%s/%s?sslmode=require",
      var.database_username,
      urlencode(var.database_password),
      module.database[0].db_instance_endpoint,
      var.database_name
    ) : var.existing_metadata_backend_url

    persist_backend_url = var.create_storage ? format(
      "s3://%s/%s:serviceaccount:%s:%s",
      module.storage[0].bucket_name,
      var.name_prefix,
      local.instance_namespace,
      var.instance_name
    ) : var.existing_persist_backend_url

    license_key = var.license_key == null ? "" : var.license_key
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
    namespace = local.instance_namespace
  }

  depends_on = [
    kubernetes_manifest.materialize_instance
  ]
}

# Create a dedicated NLB for this instance
module "nlb" {
  source = "../nlb"
  count  = var.create_nlb ? 1 : 0

  instance_name                    = var.instance_name
  name_prefix                      = var.name_prefix
  namespace                        = local.instance_namespace
  internal                         = var.internal_nlb
  subnet_ids                       = var.internal_nlb ? var.private_subnet_ids : var.public_subnet_ids
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  vpc_id                           = var.vpc_id
  mz_resource_id                   = data.kubernetes_resource.materialize_instance.object.status.resourceId

  depends_on = [
    kubernetes_manifest.materialize_instance
  ]
}

resource "kubernetes_manifest" "root_ca_cluster_issuer" {
  count = var.use_self_signed_cluster_issuer ? 1 : 0

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "${var.name_prefix}-root-ca"
    }
    "spec" = {
      "ca" = {
        "secretName" = "${var.name_prefix}-root-ca"
      }
    }
  }
}
