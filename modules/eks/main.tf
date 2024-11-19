module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access = true

  # Add CloudWatch logging
  cluster_enabled_log_types = var.cluster_enabled_log_types

  eks_managed_node_groups = {
    "${var.environment}-mz-workers" = {
      desired_size = var.node_group_desired_size
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size

      instance_types = var.node_group_instance_types
      capacity_type  = var.node_group_capacity_type

      name = "${var.environment}-mz"

      labels = {
        Environment              = var.environment
        GithubRepo               = "materialize"
        "materialize.cloud/disk" = "true"
        "workload"               = "materialize-instance"
      }
    }
  }

  access_entries = {
    current_user = {
      kubernetes_groups = ["administrators"]
      principal_arn     = local.sso_role_arn

      policy_associations = {
        eks_admin_access = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}

locals {
  # Extract the role name from the assumed role ARN
  assumed_role_name = split("/", data.aws_caller_identity.current.arn)[1]
  # Construct the IAM role ARN for SSO
  sso_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${local.assumed_role_name}"
}
