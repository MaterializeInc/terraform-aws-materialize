locals {
  name_prefix = "${var.namespace}-${var.environment}"

  # Conditionally create taints only when NVMe is enabled
  node_taints = var.enable_nvme_storage ? [
    {
      key    = "disk-unconfigured"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  ] : []

  # Conditionally add disk-config-required label
  node_labels = merge(
    {
      Environment              = var.environment
      GithubRepo               = "materialize"
      "materialize.cloud/disk" = "true"
      "workload"               = "materialize-instance"
    },
    var.enable_nvme_storage ? {
      "materialize.cloud/disk-config-required" = "true"
    } : {}
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = "${local.name_prefix}-eks"

  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access = true

  # Add CloudWatch logging
  cluster_enabled_log_types = var.cluster_enabled_log_types

  eks_managed_node_groups = {
    "${local.name_prefix}-mz" = {
      desired_size = var.node_group_desired_size
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size

      instance_types = var.node_group_instance_types
      capacity_type  = var.node_group_capacity_type
      ami_type       = var.node_group_ami_type

      name = local.name_prefix

      labels = local.node_labels

      # Conditionally add taints
      taints = local.node_taints
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  tags = var.tags
}
