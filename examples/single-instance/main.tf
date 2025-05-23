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

# Create IAM role for Materialize S3 access
resource "aws_iam_role" "materialize_s3" {
  name = "${var.name_prefix}-mz-role"

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

  tags = {
    Name      = "${var.name_prefix}-mz-role"
    ManagedBy = "terraform"
  }

  depends_on = [
    module.eks
  ]
}

# Add S3 access policy to the role
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
          # Use dynamic conditional expressions to handle cases where the bucket might not exist yet
          module.materialize_instance.bucket_arn != null ? module.materialize_instance.bucket_arn : "*",
          module.materialize_instance.bucket_arn != null ? "${module.materialize_instance.bucket_arn}/*" : "*"
        ]
      }
    ]
  })

  depends_on = [
    module.materialize_instance
  ]
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

# Define local variables for reusable configurations
locals {
  # Operator Helm values
  operator_helm_values = {
    observability = {
      podMetrics = {
        enabled = true
      }
    }
    operator = {
      cloudProvider = {
        type   = "aws"
        region = var.aws_region
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
    module.eks
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
  use_self_signed_cluster_issuer = false # TODO: This fails if Kubernetes is not ready yet
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

  name_prefix        = var.name_prefix
  operator_namespace = "materialize"

  # Use the centralized helm_values from locals
  helm_values = local.operator_helm_values

  # Install metrics server for monitoring
  install_metrics_server = true

  depends_on = [
    module.eks,
    module.aws_lbc,
    module.certificates
  ]
}

# Generate a random password for the database
resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 7. Create a Materialize instance
# module "materialize_instance" {
#   source = "../../modules/materialize-instance"

#   # General configuration
#   name_prefix        = var.name_prefix
#   instance_name      = "main"
#   instance_namespace = "materialize-environment"
#   operator_namespace = module.operator.operator_namespace

#   # Infrastructure references
#   vpc_id                     = module.networking.vpc_id
#   private_subnet_ids         = module.networking.private_subnet_ids
#   public_subnet_ids          = module.networking.public_subnet_ids
#   eks_security_group_id      = module.eks.cluster_security_group_id
#   eks_node_security_group_id = module.eks.node_security_group_id
#   oidc_provider_arn          = module.eks.oidc_provider_arn
#   cluster_oidc_issuer_url    = module.eks.cluster_oidc_issuer_url

#   # Database configuration
#   create_database      = true
#   database_name        = "materialize"
#   database_username    = "materialize"
#   database_password    = random_password.database_password.result
#   db_instance_class    = "db.t3.large"
#   db_allocated_storage = 50
#   postgres_version     = "15"
#   db_multi_az          = false

#   # Storage configuration
#   create_storage           = true
#   bucket_force_destroy     = true
#   enable_bucket_versioning = true
#   enable_bucket_encryption = true

#   # IAM configuration
#   create_iam_role = true

#   # NLB configuration
#   create_nlb                       = true
#   internal_nlb                     = false # External access
#   enable_cross_zone_load_balancing = true

#   # Instance configuration
#   # Use module defaults for environmentd_version
#   cpu_request             = "2"
#   memory_request          = "4Gi"
#   memory_limit            = "4Gi"
#   balancer_memory_request = "512Mi"
#   balancer_memory_limit   = "512Mi"
#   balancer_cpu_request    = "200m"
#   in_place_rollout        = false

#   # Environment variables
#   environmentd_extra_env = [
#     {
#       name  = "MZ_PERSISTENCE_BACKEND_READ_ONLY_MODE_ENABLED"
#       value = "false"
#     }
#   ]

#   depends_on = [
#     module.operator,
#     module.openebs,
#     module.aws_lbc,
#     module.certificates,
#     module.networking,
#     module.eks,
#   ]
# }
