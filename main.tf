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

  tags = local.common_tags
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
}

module "operator" {
  count  = var.install_materialize_operator ? 1 : 0
  source = "./modules/operator"

  namespace              = var.namespace
  environment            = var.environment
  instances              = var.materialize_instances
  iam_role_arn           = aws_iam_role.materialize_s3.arn
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  s3_bucket_name         = module.storage.bucket_name
  postgres_version       = var.postgres_version

  providers = {
    kubernetes = kubernetes,
    helm       = helm
  }

  depends_on = [
    module.eks,
    module.storage,
    module.database
  ]
}

locals {
  network_id                 = var.create_vpc ? module.networking.vpc_id : var.network_id
  network_private_subnet_ids = var.create_vpc ? module.networking.private_subnet_ids : var.network_private_subnet_ids

  # instance_backend_urls = {
  #   for instance in var.materialize_instances : instance.name => {
  #     metadata_backend_url = format(
  #       "postgres://%s:%s@%s/%s?sslmode=require",
  #       coalesce(instance.database_username, var.database_username),
  #       coalesce(instance.database_password, var.database_password),
  #       module.database.db_instance_endpoint,
  #       coalesce(instance.database_name, "${instance.name}_db")
  #     )
  #     persist_backend_url = format(
  #       "s3://%s/%s/%s:serviceaccount:%s:%s",
  #       module.storage.bucket_name,
  #       var.environment,
  #       instance.name,
  #       coalesce(instance.namespace, "materialize-environment"),
  #       instance.instance_id
  #     )
  #   }
  # }

  # Common tags that apply to all resources
  common_tags = merge(
    var.tags,
    {
      Namespace   = var.namespace
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

resource "aws_cloudwatch_log_group" "materialize" {
  count = var.enable_monitoring ? 1 : 0

  name              = "/aws/${var.log_group_name_prefix}/${module.eks.cluster_name}/${var.environment}"
  retention_in_days = var.metrics_retention_days

  tags = var.tags
}

resource "aws_iam_user" "materialize" {
  name = "${local.name_prefix}-mz-user"
}

resource "aws_iam_access_key" "materialize_user" {
  user = aws_iam_user.materialize.name
}

resource "aws_iam_user_policy" "materialize_s3" {
  name = "${local.name_prefix}-mz-s3-policy"
  user = aws_iam_user.materialize.name

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

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
