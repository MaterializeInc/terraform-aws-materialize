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
      # Desired node count is is ignored after first run
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
        "materialize.cloud/disk" = var.enable_disk_setup ? "true" : "false"
        "workload"               = "materialize-instance"
      }
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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

# Karpenter Namespace
resource "aws_security_group" "karpenter" {
  count       = var.install_karpenter ? 1 : 0
  name_prefix = "${local.name_prefix}-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [module.eks.node_security_group_id, module.eks.cluster_security_group_id]
    description     = "Allow access from the eks security group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "kubernetes_namespace" "karpenter" {
  count = var.install_karpenter ? 1 : 0

  metadata {
    name = var.karpenter_namespace
  }
}

# Karpenter IAM Role
resource "aws_iam_role" "karpenter" {
  count = var.install_karpenter ? 1 : 0

  name = "${local.name_prefix}-karpenter"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_service_account}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Karpenter IAM Policy
resource "aws_iam_role_policy" "karpenter" {
  count = var.install_karpenter ? 1 : 0

  name = "${local.name_prefix}-karpenter"
  role = aws_iam_role.karpenter[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeImages",
          "ec2:DescribeSpotPriceHistory",
          "ssm:GetParameter",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "eks:DescribeCluster",
          "pricing:GetProducts"
        ]
        Resource = "*"
      }
    ]
  })
}

# Karpenter Service Account
resource "kubernetes_service_account" "karpenter" {
  count = var.install_karpenter ? 1 : 0

  metadata {
    name      = var.karpenter_service_account
    namespace = var.karpenter_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter[0].arn
    }
  }

  depends_on = [kubernetes_namespace.karpenter]
}

# Karpenter Helm Chart
resource "helm_release" "karpenter" {
  count = var.install_karpenter ? 1 : 0

  name       = "karpenter"
  namespace  = var.karpenter_namespace
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  set {
    name  = "serviceAccount.name"
    value = var.karpenter_service_account
  }

  set {
    name  = "serviceAccount.create"
    value = false
  }

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "settings.defaultInstanceProfile"
    value = module.eks.eks_managed_node_groups["${local.name_prefix}-mz"].iam_role_name
  }

  dynamic "set" {
    for_each = var.karpenter_settings
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_service_account.karpenter,
    aws_iam_role_policy.karpenter
  ]
}
