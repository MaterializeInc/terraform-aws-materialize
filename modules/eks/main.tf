locals {
  name_prefix = "${var.namespace}-${var.environment}"

  disk_setup_script = file("${path.module}/bootstrap.sh")
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = "${local.name_prefix}-eks"

  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access = true

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

      labels = {
        Environment              = var.environment
        GithubRepo               = "materialize"
        "materialize.cloud/disk" = "false"
        "workload"               = "materialize-instance"
      }

      cloudinit_pre_nodeadm = [
        {
          content_type = "text/x-shellscript"
          content      = local.disk_setup_script
        },
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  failSwapOn: false
                  featureGates:
                    NodeSwap: true
                  memorySwap:
                    swapBehavior: LimitedSwap
          EOT
        },
      ]
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

# Install OpenEBS for lgalloc support
resource "kubernetes_namespace" "openebs" {
  count = var.install_openebs ? 1 : 0

  metadata {
    name = var.openebs_namespace
  }
}

resource "helm_release" "openebs" {
  count = var.install_openebs ? 1 : 0

  name       = "openebs"
  namespace  = kubernetes_namespace.openebs[0].metadata[0].name
  repository = "https://openebs.github.io/openebs"
  chart      = "openebs"
  version    = var.openebs_version

  set {
    name  = "engines.replicated.mayastor.enabled"
    value = "false"
  }

  depends_on = [kubernetes_namespace.openebs]
}
