provider "aws" {
  region = var.aws_region
}

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
  source                                   = "../../modules/eks"
  name_prefix                              = var.name_prefix
  cluster_version                          = "1.28"
  vpc_id                                   = module.networking.vpc_id
  private_subnet_ids                       = module.networking.private_subnet_ids
  cluster_enabled_log_types                = ["api", "audit"]
  enable_cluster_creator_admin_permissions = true
  tags                                     = {}
}

# 2.1. Create EKS node group
module "eks_node_group" {
  source                            = "../../modules/eks-node-group"
  cluster_name                      = module.eks.cluster_name
  subnet_ids                        = module.networking.private_subnet_ids
  node_group_name                   = "${var.name_prefix}-mz"
  enable_disk_setup                 = true
  cluster_service_cidr              = module.eks.cluster_service_cidr
  cluster_primary_security_group_id = module.eks.node_security_group_id

  labels = {
    GithubRepo               = "materialize"
    "materialize.cloud/disk" = "true"
    "workload"               = "materialize-instance"
  }
}

# 3. Install AWS Load Balancer Controller
module "aws_lbc" {
  source = "../../modules/aws-lbc"

  name_prefix       = var.name_prefix
  eks_cluster_name  = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.cluster_oidc_issuer_url
  vpc_id            = module.networking.vpc_id
  region            = var.aws_region

  depends_on = [
    module.eks,
    module.eks_node_group,
  ]
}

# 4. Install OpenEBS for storage
module "openebs" {
  source = "../../modules/openebs"

  install_openebs   = true
  openebs_namespace = "openebs"
  openebs_version   = "4.2.0"

  depends_on = [
    module.networking,
    module.eks,
    module.eks_node_group,
    module.aws_lbc,
  ]
}

# 5. Install Certificate Manager for TLS
module "certificates" {
  source = "../../modules/certificates"

  install_cert_manager           = true
  cert_manager_install_timeout   = 300
  cert_manager_chart_version     = "v1.13.3"
  use_self_signed_cluster_issuer = var.install_materialize_instance
  cert_manager_namespace         = "cert-manager"
  name_prefix                    = var.name_prefix

  depends_on = [
    module.networking,
    module.eks,
    module.eks_node_group,
    module.aws_lbc,
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
  use_self_signed_cluster_issuer = true

  depends_on = [
    module.eks,
    module.networking,
    module.eks_node_group,
  ]
}

resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 7. Setup dedicated database instance for Materialize
module "database" {
  source                     = "../../modules/database"
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

# 8. Setup S3 bucket for Materialize
module "storage" {
  source                 = "../../modules/storage"
  name_prefix            = var.name_prefix
  bucket_lifecycle_rules = []
  bucket_force_destroy   = true

  # For testing purposes, we are disabling encryption and versioning to allow for easier cleanup
  # This should be enabled in production environments for security and data integrity
  enable_bucket_versioning = false
  enable_bucket_encryption = false

  tags = {}
}

# 9. Setup Materialize instance
module "materialize_instance" {
  count = var.install_materialize_instance ? 1 : 0

  source               = "../../modules/materialize-instance"
  instance_name        = "main"
  instance_namespace   = "materialize-environment"
  operator_namespace   = module.operator.operator_namespace
  metadata_backend_url = local.metadata_backend_url
  persist_backend_url  = local.persist_backend_url

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

# 10. Setup dedicated NLB for Materialize instance
module "materialize_nlb" {
  count = var.install_materialize_instance && var.create_nlb ? 1 : 0

  source = "../../modules/nlb"

  instance_name                    = "main"
  name_prefix                      = var.name_prefix
  namespace                        = "materialize-environment"
  internal                         = var.internal_nlb
  subnet_ids                       = var.internal_nlb ? module.networking.private_subnet_ids : module.networking.public_subnet_ids
  enable_cross_zone_load_balancing = true
  vpc_id                           = module.networking.vpc_id
  mz_resource_id                   = module.materialize_instance[0].instance_resource_id

  depends_on = [
    module.materialize_instance
  ]
}

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

data "aws_caller_identity" "current" {}
