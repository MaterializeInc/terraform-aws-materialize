module "networking" {
  source = "./modules/networking"

  # The namespace and environment variables are used to construct the names of the resources
  # e.g. ${namespace}-${environment}-vpc
  namespace   = var.namespace
  environment = var.environment

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway

  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  # The namespace and environment variables are used to construct the names of the resources
  # e.g. ${namespace}-${environment}-eks
  namespace   = var.namespace
  environment = var.environment

  cluster_version                          = var.cluster_version
  vpc_id                                   = local.network_id
  private_subnet_ids                       = local.network_private_subnet_ids
  node_group_desired_size                  = var.node_group_desired_size
  node_group_min_size                      = var.node_group_min_size
  node_group_max_size                      = var.node_group_max_size
  node_group_instance_types                = var.node_group_instance_types
  node_group_ami_type                      = var.node_group_ami_type
  cluster_enabled_log_types                = var.cluster_enabled_log_types
  node_group_capacity_type                 = var.node_group_capacity_type
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  install_openebs   = local.disk_config.install_openebs
  enable_disk_setup = local.disk_config.run_disk_setup_script
  openebs_namespace = local.disk_config.openebs_namespace
  openebs_version   = local.disk_config.openebs_version

  tags = local.common_tags

  depends_on = [
    module.networking,
  ]
}

module "swap_node_group" {
  source = "./modules/eks-node-group"
  count  = var.swap_enabled ? 1 : 0

  cluster_name                      = module.eks.cluster_name
  subnet_ids                        = local.network_private_subnet_ids
  node_group_name                   = "${local.name_prefix}-mz-swap"
  instance_types                    = var.node_group_instance_types
  swap_enabled                      = true
  min_size                          = var.node_group_min_size
  max_size                          = var.node_group_max_size
  desired_size                      = var.node_group_desired_size
  cluster_service_cidr              = module.eks.cluster_service_cidr
  cluster_primary_security_group_id = module.eks.node_security_group_id

  labels = {
    "materialize.cloud/swap" = "true"
    "workload"               = "materialize-instance"
  }

  tags = merge(
    local.common_tags,
    {
      Swap = "true"
    }
  )

  depends_on = [
    module.eks,
  ]
}

module "aws_lbc" {
  source = "./modules/aws-lbc"
  count  = var.install_aws_load_balancer_controller ? 1 : 0

  name_prefix       = local.name_prefix
  eks_cluster_name  = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  vpc_id            = module.networking.vpc_id
  region            = data.aws_region.current.name

  depends_on = [
    module.eks,
  ]
}

module "storage" {
  source = "./modules/storage"

  # The namespace and environment variables are used to construct the names of the resources
  # e.g. ${namespace}-${environment}-storage
  namespace   = var.namespace
  environment = var.environment

  bucket_lifecycle_rules   = var.bucket_lifecycle_rules
  enable_bucket_encryption = var.enable_bucket_encryption
  enable_bucket_versioning = var.enable_bucket_versioning
  bucket_force_destroy     = var.bucket_force_destroy

  tags = local.common_tags
}

module "database" {
  source = "./modules/database"

  # The namespace and environment variables are used to construct the names of the resources
  # e.g. ${namespace}-${environment}-db
  namespace   = var.namespace
  environment = var.environment

  postgres_version           = var.postgres_version
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  database_name              = var.database_name
  database_username          = var.database_username
  multi_az                   = var.db_multi_az
  database_subnet_ids        = local.network_private_subnet_ids
  vpc_id                     = local.network_id
  eks_security_group_id      = module.eks.cluster_security_group_id
  eks_node_security_group_id = module.eks.node_security_group_id
  max_allocated_storage      = var.db_max_allocated_storage
  database_password          = var.database_password

  tags = local.common_tags

  depends_on = [
    module.networking,
  ]
}

module "certificates" {
  source = "./modules/certificates"

  install_cert_manager           = var.install_cert_manager
  cert_manager_install_timeout   = var.cert_manager_install_timeout
  cert_manager_chart_version     = var.cert_manager_chart_version
  use_self_signed_cluster_issuer = var.use_self_signed_cluster_issuer && length(var.materialize_instances) > 0
  cert_manager_namespace         = var.cert_manager_namespace
  name_prefix                    = local.name_prefix

  depends_on = [
    module.eks,
    # The AWS LBC installs webhooks, and all other K8S stuff can fail
    # if they are deployed, but the AWS LBC pods aren't up yet.
    # This doesn't actually need the LBC,
    # but we want to avoid concurrently updating these.
    module.aws_lbc,
  ]
}

module "operator" {
  source = "github.com/MaterializeInc/terraform-helm-materialize?ref=v0.1.34"

  count = var.install_materialize_operator ? 1 : 0

  install_metrics_server = var.install_metrics_server

  depends_on = [
    module.eks,
    module.swap_node_group,
    module.database,
    module.storage,
    module.networking,
    module.certificates,
    # The AWS LBC installs webhooks, and all other K8S stuff can fail
    # if they are deployed, but the AWS LBC pods aren't up yet.
    # This doesn't actually need the LBC,
    # but we want to avoid concurrently updating these.
    module.aws_lbc,
  ]

  namespace          = var.namespace
  environment        = var.environment
  operator_version   = var.operator_version
  operator_namespace = var.operator_namespace

  helm_values = local.merged_helm_values
  instances   = local.instances

  // For development purposes, you can use a local Helm chart instead of fetching it from the Helm repository
  use_local_chart = var.use_local_chart
  helm_chart      = var.helm_chart

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "nlb" {
  source = "./modules/nlb"

  for_each = { for idx, instance in local.instances : instance.name => instance if lookup(instance, "create_nlb", true) }

  instance_name                    = each.value.name
  name_prefix                      = "${local.name_prefix}-${each.value.name}"
  namespace                        = each.value.namespace
  internal                         = each.value.internal_nlb
  subnet_ids                       = each.value.internal_nlb ? local.network_private_subnet_ids : local.network_public_subnet_ids
  enable_cross_zone_load_balancing = each.value.enable_cross_zone_load_balancing
  vpc_id                           = local.network_id
  mz_resource_id                   = module.operator[0].materialize_instance_resource_ids[each.value.name]

  depends_on = [
    module.aws_lbc,
    module.operator,
    module.eks,
  ]
}

locals {
  network_id                 = var.create_vpc ? module.networking.vpc_id : var.network_id
  network_private_subnet_ids = var.create_vpc ? module.networking.private_subnet_ids : var.network_private_subnet_ids
  network_public_subnet_ids  = var.create_vpc ? module.networking.public_subnet_ids : var.network_public_subnet_ids

  default_helm_values = {
    observability = {
      podMetrics = {
        enabled = true
      }
    }
    operator = {
      clusters = {
        swap_enabled = var.swap_enabled
      }
      image = var.orchestratord_version == null ? {} : {
        tag = var.orchestratord_version
      },
      cloudProvider = {
        type   = "aws"
        region = data.aws_region.current.name
        providers = {
          aws = {
            enabled   = true
            accountID = data.aws_caller_identity.current.account_id
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
    tls = (var.use_self_signed_cluster_issuer && length(var.materialize_instances) > 0) ? {
      defaultCertificateSpecs = {
        balancerdExternal = {
          dnsNames = [
            "balancerd",
          ]
          issuerRef = {
            name = module.certificates.cluster_issuer_name
            kind = "ClusterIssuer"
          }
        }
        consoleExternal = {
          dnsNames = [
            "console",
          ]
          issuerRef = {
            name = module.certificates.cluster_issuer_name
            kind = "ClusterIssuer"
          }
        }
        internal = {
          issuerRef = {
            name = module.certificates.cluster_issuer_name
            kind = "ClusterIssuer"
          }
        }
      }
    } : {}
  }

  merged_helm_values = provider::deepmerge::mergo(local.default_helm_values, var.helm_values)

  instances = [
    for instance in var.materialize_instances : {
      name                             = instance.name
      namespace                        = instance.namespace
      database_name                    = instance.database_name
      create_database                  = instance.create_database
      environmentd_version             = instance.environmentd_version
      create_nlb                       = instance.create_nlb
      internal_nlb                     = instance.internal_nlb
      enable_cross_zone_load_balancing = instance.enable_cross_zone_load_balancing
      environmentd_extra_args          = instance.environmentd_extra_args

      metadata_backend_url = format(
        "postgres://%s:%s@%s/%s?sslmode=require",
        var.database_username,
        urlencode(var.database_password),
        module.database.db_instance_endpoint,
        coalesce(instance.database_name, instance.name)
      )

      persist_backend_url = format(
        "s3://%s/%s-%s:serviceaccount:%s:%s",
        module.storage.bucket_name,
        var.environment,
        instance.name,
        coalesce(instance.namespace, var.operator_namespace),
        instance.name
      )

      license_key = instance.license_key

      authenticator_kind = instance.authenticator_kind

      external_login_password_mz_system = instance.external_login_password_mz_system != null ? instance.external_login_password_mz_system : null

      cpu_request    = instance.cpu_request
      memory_request = instance.memory_request
      memory_limit   = instance.memory_limit

      balancer_cpu_request    = instance.balancer_cpu_request
      balancer_memory_request = instance.balancer_memory_request
      balancer_memory_limit   = instance.balancer_memory_limit

      # Rollout options
      in_place_rollout = instance.in_place_rollout
      request_rollout  = instance.request_rollout
      force_rollout    = instance.force_rollout
    }
  ]

  # Common tags that apply to all resources
  common_tags = merge(
    var.tags,
    {
      Namespace   = var.namespace
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # Disk support configuration
  disk_config = {
    install_openebs           = var.enable_disk_support ? lookup(var.disk_support_config, "install_openebs", true) : false
    run_disk_setup_script     = var.enable_disk_support ? lookup(var.disk_support_config, "run_disk_setup_script", true) : false
    create_storage_class      = var.enable_disk_support ? lookup(var.disk_support_config, "create_storage_class", true) : false
    openebs_version           = lookup(var.disk_support_config, "openebs_version", "4.3.3")
    openebs_namespace         = lookup(var.disk_support_config, "openebs_namespace", "openebs")
    storage_class_name        = lookup(var.disk_support_config, "storage_class_name", "openebs-lvm-instance-store-ext4")
    storage_class_provisioner = lookup(var.disk_support_config, "storage_class_provisioner", "local.csi.openebs.io")
    storage_class_parameters = {
      storage  = try(var.disk_support_config.storage_class_parameters.storage, "lvm")
      fsType   = try(var.disk_support_config.storage_class_parameters.fsType, "ext4")
      volgroup = try(var.disk_support_config.storage_class_parameters.volgroup, "instance-store-vg")
    }
  }
}

resource "aws_cloudwatch_log_group" "materialize" {
  count = var.enable_monitoring ? 1 : 0

  name              = "/aws/${var.log_group_name_prefix}/${module.eks.cluster_name}/${var.environment}"
  retention_in_days = var.metrics_retention_days

  tags = var.tags
}

resource "aws_iam_role" "materialize_s3" {
  name = "${local.name_prefix}-mz-role"

  # Trust policy allowing EKS to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub" : "system:serviceaccount:*:*",
            "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = local.common_tags

  depends_on = [
    module.eks
  ]
}

resource "aws_iam_role_policy" "materialize_s3" {
  name = "${local.name_prefix}-mz-role-policy"
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
          module.storage.bucket_arn,
          "${module.storage.bucket_arn}/*"
        ]
      }
    ]
  })
}

locals {
  name_prefix = "${var.namespace}-${var.environment}"
}
