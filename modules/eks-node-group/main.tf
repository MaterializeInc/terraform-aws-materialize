locals {
  disk_setup_script = file("${path.module}/bootstrap.sh")
}

module "node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  subnet_ids      = var.subnet_ids
  name            = var.node_group_name
  desired_size    = var.desired_size
  min_size        = var.min_size
  max_size        = var.max_size
  instance_types  = var.instance_types
  capacity_type   = var.capacity_type
  ami_type        = var.ami_type
  labels          = var.labels

  cloudinit_pre_nodeadm = var.enable_disk_setup ? [
    {
      content_type = "text/x-shellscript"
      content      = local.disk_setup_script
    }
  ] : []

  cluster_service_cidr = var.cluster_service_cidr
  cluster_primary_security_group_id = var.cluster_primary_security_group_id
} 
