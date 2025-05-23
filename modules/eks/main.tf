locals {
  disk_setup_script = file("${path.module}/bootstrap.sh")
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = "${var.name_prefix}-eks"

  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access = true

  cluster_enabled_log_types = var.cluster_enabled_log_types

  eks_managed_node_groups = {
    "${var.name_prefix}-mz" = {
      desired_size = var.node_group_desired_size
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size

      instance_types = var.node_group_instance_types
      capacity_type  = var.node_group_capacity_type
      ami_type       = var.node_group_ami_type

      name = var.name_prefix

      labels = {
        GithubRepo               = "materialize"
        "materialize.cloud/disk" = var.enable_disk_setup ? "true" : "false"
        "workload"               = "materialize-instance"
      }

      cloudinit_pre_nodeadm = var.enable_disk_setup ? [
        {
          content_type = "text/x-shellscript"
          content      = local.disk_setup_script
        }
      ] : []

    }
  }

  node_security_group_additional_rules = {
    mz_ingress_http = {
      description      = "Ingress to materialize balancers HTTP"
      protocol         = "tcp"
      from_port        = 6876
      to_port          = 6876
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    mz_ingress_pgwire = {
      description      = "Ingress to materialize balancers pgwire"
      protocol         = "tcp"
      from_port        = 6875
      to_port          = 6875
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    mz_ingress_nlb_health_checks = {
      description      = "Ingress to materialize balancer health checks and console"
      protocol         = "tcp"
      from_port        = 8080
      to_port          = 8080
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  tags = var.tags
}
