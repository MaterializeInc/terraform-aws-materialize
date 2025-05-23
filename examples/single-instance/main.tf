# Single Instance Example
# This example shows how to deploy a single Materialize instance with default settings.

provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# 1. Create network infrastructure
module "networking" {
  source = "../../modules/networking"

  name_prefix = var.name_prefix

  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  single_nat_gateway   = true # Use single NAT gateway to reduce costs for this example
}

# 2. Create EKS cluster
module "eks" {
  source = "../../modules/eks"

  name_prefix = var.name_prefix

  cluster_version                          = "1.28"
  vpc_id                                   = module.networking.vpc_id
  private_subnet_ids                       = module.networking.private_subnet_ids
  node_group_desired_size                  = 2
  node_group_min_size                      = 2
  node_group_max_size                      = 3
  node_group_instance_types                = ["r7g.xlarge"] # Use optimized instances for Materialize
  node_group_ami_type                      = "AL2023_ARM_64_STANDARD"
  cluster_enabled_log_types                = ["api", "audit"]
  node_group_capacity_type                 = "ON_DEMAND"
  enable_cluster_creator_admin_permissions = true

  depends_on = [
    module.networking,
  ]

  providers = {
    aws        = aws
    kubernetes = kubernetes
    helm       = helm
  }
}

# 3. Install OpenEBS for storage
module "openebs" {
  source = "../../modules/openebs"

  install_openebs   = true
  openebs_namespace = "openebs"
  openebs_version   = "4.2.0"

  depends_on = [
    module.eks,
    module.networking,
  ]
}

# 4. Install AWS Load Balancer Controller
module "aws_lbc" {
  source = "../../modules/aws-lbc"

  name_prefix       = var.name_prefix
  eks_cluster_name  = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  vpc_id            = module.networking.vpc_id
  region            = var.aws_region

  depends_on = [
    module.eks
  ]
}

# 5. Install Certificate Manager for TLS
module "certificates" {
  source = "../../modules/certificates"

  install_cert_manager           = true
  cert_manager_install_timeout   = 300
  cert_manager_chart_version     = "v1.13.3"
  use_self_signed_cluster_issuer = true # TODO: This fails if Kubernetes is not ready yet
  cert_manager_namespace         = "cert-manager"
  name_prefix                    = var.name_prefix

  depends_on = [
    module.eks,
    module.aws_lbc
  ]
}

# 6. Install Materialize Operator
module "operator" {
  source = "../../modules/operator"

  name_prefix                    = var.name_prefix
  aws_region                     = var.aws_region
  aws_account_id                 = data.aws_caller_identity.current.account_id
  oidc_provider_arn              = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url        = module.eks.cluster_oidc_issuer_url
  s3_bucket_arn                  = module.storage.bucket_arn
  use_self_signed_cluster_issuer = var.use_self_signed_cluster_issuer

  depends_on = [
    module.eks,
    module.networking,
  ]
}

resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Add module "database"
module "database" {
  source = "../../modules/database"
  name_prefix                = var.name_prefix
  postgres_version           = "15"
  instance_class             = "db.t3.large"
  allocated_storage          = 50
  max_allocated_storage      = 100
  database_name              = "materialize"
  database_username          = "materialize"
  database_password          = random_password.database_password.result
  multi_az                   = false
  database_subnet_ids        = module.networking.private_subnet_ids
  vpc_id                     = module.networking.vpc_id
  eks_security_group_id      = module.eks.cluster_security_group_id
  eks_node_security_group_id = module.eks.node_security_group_id
  tags                       = {}
}

# Add module "storage"
module "storage" {
  source = "../../modules/storage"
  name_prefix               = var.name_prefix
  bucket_lifecycle_rules    = []
  enable_bucket_encryption  = true
  enable_bucket_versioning  = true
  bucket_force_destroy      = true
  tags                      = {}
}

# Add locals for backend URLs
locals {
  metadata_backend_url = format(
    "postgres://%s:%s@%s/%s?sslmode=require",
    module.database.db_instance_username,
    urlencode(random_password.database_password.result),
    module.database.db_instance_endpoint,
    module.database.db_instance_name
  )

  persist_backend_url = format(
    "s3://%s/%s:serviceaccount:%s:%s",
    module.storage.bucket_name,
    var.name_prefix,
    "materialize-environment",
    "main"
  )
}

module "materialize_instance" {
  source = "../../modules/materialize-instance"
  name_prefix                = var.name_prefix
  instance_name              = "main"
  instance_namespace         = "materialize-environment"
  operator_namespace         = module.operator.operator_namespace
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  public_subnet_ids          = module.networking.public_subnet_ids
  eks_security_group_id      = module.eks.cluster_security_group_id
  eks_node_security_group_id = module.eks.node_security_group_id
  oidc_provider_arn          = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url    = module.eks.cluster_oidc_issuer_url
  materialize_iam_role_arn   = module.operator.materialize_s3_iam_role_arn
  metadata_backend_url       = local.metadata_backend_url
  persist_backend_url        = local.persist_backend_url

  depends_on = [
    module.eks,
    module.database,
    module.storage,
    module.networking,
    module.certificates,
    module.operator,
    module.aws_lbc,
  ]
}
