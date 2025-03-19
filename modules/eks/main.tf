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

# NVMe disk setup components - only created when NVMe storage is enabled
resource "kubernetes_service_account" "nvme_setup" {
  count = var.enable_nvme_storage ? 1 : 0

  metadata {
    name      = "nvme-setup-sa"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "node_taint_manager" {
  count = var.enable_nvme_storage ? 1 : 0

  metadata {
    name = "node-taint-manager"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "patch", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "nvme_setup_taint_binding" {
  count = var.enable_nvme_storage ? 1 : 0

  metadata {
    name = "nvme-setup-taint-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.node_taint_manager[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nvme_setup[0].metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_daemon_set_v1" "nvme_disk_setup" {
  count = var.enable_nvme_storage ? 1 : 0

  metadata {
    name      = "nvme-disk-setup"
    namespace = "kube-system"
  }

  spec {
    selector {
      match_labels = {
        app = "nvme-disk-setup"
      }
    }

    template {
      metadata {
        labels = {
          app = "nvme-disk-setup"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.nvme_setup[0].metadata[0].name

        # Use init container to set up NVMe disks
        init_container {
          name  = "setup-nvme"
          image = var.nvme_bootstrap_image

          security_context {
            privileged = true
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name  = "CLOUD_PROVIDER"
            value = "aws"
          }

          volume_mount {
            name       = "host-dev"
            mount_path = "/dev"
          }

          volume_mount {
            name       = "host-sys"
            mount_path = "/sys"
          }

          volume_mount {
            name       = "host-proc"
            mount_path = "/proc"
          }

          command = [
            "/bin/bash",
            "-c",
            <<-EOT
            # Run the disk configuration script with explicit cloud provider
            /usr/local/bin/configure-disks.sh --cloud-provider aws

            # Remove taint once configuration is complete
            /usr/local/bin/manage-taints.sh remove
            EOT
          ]
        }

        # Main container is just a pause container
        container {
          name  = "pause"
          image = "k8s.gcr.io/pause:3.7"
        }

        volume {
          name = "host-dev"
          host_path {
            path = "/dev"
          }
        }

        volume {
          name = "host-sys"
          host_path {
            path = "/sys"
          }
        }

        volume {
          name = "host-proc"
          host_path {
            path = "/proc"
          }
        }

        # Allow this DaemonSet to run on nodes with the disk-unconfigured taint
        toleration {
          key      = "disk-unconfigured"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        # Only run on nodes that need disk configuration
        node_selector = {
          "materialize.cloud/disk-config-required" = "true"
        }
      }
    }
  }

  depends_on = [
    module.eks,
    kubernetes_cluster_role_binding.nvme_setup_taint_binding
  ]
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
