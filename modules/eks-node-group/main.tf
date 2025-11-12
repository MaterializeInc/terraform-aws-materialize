locals {
  node_labels = merge(
    var.labels,
    var.swap_enabled ? {
      "materialize.cloud/swap"                 = "true"
      "materialize.cloud/disk-config-required" = "true"
    } : {}
  )

  swap_bootstrap_args = <<-EOF
    [settings.bootstrap-containers.diskstrap]
    source = "${var.disk_setup_image}"
    mode = "always"
    essential = true
    user-data = "${base64encode(jsonencode(["swap", "--cloud-provider", "aws", "--bottlerocket-enable-swap"]))}"

    [settings.kernel.sysctl]
    "vm.swappiness" = "100"
    "vm.min_free_kbytes" = "1048576"
    "vm.watermark_scale_factor" = "100"
  EOF
}

module "node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.0"

  cluster_name   = var.cluster_name
  subnet_ids     = var.subnet_ids
  name           = var.node_group_name
  desired_size   = var.desired_size
  min_size       = var.min_size
  max_size       = var.max_size
  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  ami_type       = var.ami_type
  labels         = local.node_labels

  taints = var.node_taints

  # useful to disable this when prefix might be too long and hit following char limit
  # expected length of name_prefix to be in the range (1 - 38)
  iam_role_use_name_prefix = var.iam_role_use_name_prefix

  bootstrap_extra_args = var.swap_enabled ? local.swap_bootstrap_args : ""

  cluster_service_cidr              = var.cluster_service_cidr
  cluster_primary_security_group_id = var.cluster_primary_security_group_id

  tags = var.tags
}
