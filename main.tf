module "networking" {
  source = "./modules/networking"

  vpc_name             = var.vpc_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_name         = var.cluster_name
  single_nat_gateway   = var.single_nat_gateway
  tags                 = var.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.cluster_version
  vpc_id                                   = module.networking.vpc_id
  private_subnet_ids                       = module.networking.private_subnet_ids
  environment                              = var.environment
  node_group_desired_size                  = var.node_group_desired_size
  node_group_min_size                      = var.node_group_min_size
  node_group_max_size                      = var.node_group_max_size
  node_group_instance_types                = var.node_group_instance_types
  tags                                     = var.tags
  cluster_enabled_log_types                = var.cluster_enabled_log_types
  node_group_capacity_type                 = var.node_group_capacity_type
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
}

module "storage" {
  source = "./modules/storage"

  bucket_name              = var.bucket_name
  tags                     = var.tags
  bucket_lifecycle_rules   = var.bucket_lifecycle_rules
  enable_bucket_encryption = var.enable_bucket_encryption
  enable_bucket_versioning = var.enable_bucket_versioning
  bucket_force_destroy     = var.bucket_force_destroy
}

module "database" {
  source = "./modules/database"

  db_identifier              = var.db_identifier
  postgres_version           = var.postgres_version
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  database_name              = var.database_name
  database_username          = var.database_username
  multi_az                   = var.db_multi_az
  database_subnet_ids        = module.networking.private_subnet_ids
  vpc_id                     = module.networking.vpc_id
  eks_security_group_id      = module.eks.cluster_security_group_id
  eks_node_security_group_id = module.eks.node_security_group_id
  tags                       = var.tags
  max_allocated_storage      = var.db_max_allocated_storage
  database_password          = var.database_password
}

resource "aws_cloudwatch_log_group" "materialize" {
  count = var.enable_monitoring ? 1 : 0

  name              = "/aws/materialize/${var.environment}"
  retention_in_days = var.metrics_retention_days

  tags = var.tags
}

resource "aws_iam_user" "materialize" {
  name = "${var.environment}-materialize-user"
}

resource "aws_iam_access_key" "materialize_user" {
  user = aws_iam_user.materialize.name
}

resource "aws_iam_user_policy" "materialize_s3" {
  name = "materialize-s3-access"
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
  name = "${var.environment}-materialize-s3-role"

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
          StringEquals = {
            "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub" : "${var.bucket_prefix}:serviceaccount:${var.namespace}:${var.service_account_name}",
            "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags

  depends_on = [
    module.eks
  ]
}

# Attach S3 bucket policy to the role
resource "aws_iam_role_policy" "materialize_s3" {
  name = "materialize-s3-access"
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
