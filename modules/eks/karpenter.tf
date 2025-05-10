resource "kubectl_manifest" "karpenter_node_class" {
  count           = var.install_karpenter ? 1 : 0
  force_conflicts = true


  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "${local.name_prefix}-node-class2"
    }
    spec = {
      amiSelectorTerms = [{
        alias = "al2023@latest"
      }]
      role = module.eks.eks_managed_node_groups["${local.name_prefix}-mz"].iam_role_name
      subnetSelectorTerms = [
        for sn_id in var.private_subnet_ids :
        {
          id = sn_id
        }
      ]
      securityGroupSelectorTerms = [
        {
          id = module.eks.node_security_group_id
        }
      ]
      kubelet = {
        clusterDNS = [cidrhost(module.eks.cluster_service_cidr, 10)]
      }
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            deleteOnTermination = true
            volumeSize          = "20Gi"
            volumeType          = "gp3"
            encrypted           = true
          }
        }
      ]

      userData = var.enable_disk_setup ? local.disk_setup_script : ""
      tags = merge(var.tags, {
        Name = "${local.name_prefix}-karpenter"
      })
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "enabled"
        httpPutResponseHopLimit = 3
        httpTokens              = "required"
      }
    }
  })

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  count           = var.install_karpenter ? 1 : 0
  force_conflicts = true

  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "${local.name_prefix}-node-pool2"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "Environment"            = var.environment
            "Name"                   = "${local.name_prefix}-karpenter_node_pool"
            "materialize.cloud/disk" = var.enable_disk_setup ? "true" : "false"
            "workload"               = "materialize-instance-karpenter"
          }
        }
        spec = {
          expireAfter = "Never"
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "${local.name_prefix}-node-class2"
          }
          requirements = [
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = var.karpenter_instance_sizes
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand", "reserved"]
            }
          ]
        }
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "15s"

      }
    }
  })

  depends_on = [kubectl_manifest.karpenter_node_class]
}
