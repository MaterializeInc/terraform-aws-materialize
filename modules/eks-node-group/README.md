## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_node_group"></a> [node\_group](#module\_node\_group) | terraform-aws-modules/eks/aws//modules/eks-managed-node-group | ~> 20.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | AMI type for the node group. | `string` | `"BOTTLEROCKET_ARM_64"` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Capacity type for worker nodes (ON\_DEMAND or SPOT). | `string` | `"ON_DEMAND"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster to attach the node group to. | `string` | n/a | yes |
| <a name="input_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#input\_cluster\_primary\_security\_group\_id) | The ID of the primary security group for the cluster | `string` | n/a | yes |
| <a name="input_cluster_service_cidr"></a> [cluster\_service\_cidr](#input\_cluster\_service\_cidr) | The CIDR block for the cluster service | `string` | n/a | yes |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired number of worker nodes. | `number` | `1` | no |
| <a name="input_disk_setup_image"></a> [disk\_setup\_image](#input\_disk\_setup\_image) | Docker image for the disk setup script | `string` | `"docker.io/materialize/ephemeral-storage-setup-image:v0.4.0"` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Use name prefix for IAM roles | `bool` | `true` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Instance types for worker nodes.<br/><br/>Recommended Configuration:<br/>- For other workloads: `r7g`, `r6g` families (ARM-based Graviton, without local disks)<br/>- For materialize instance workloads: `r6gd`, `r7gd` families (ARM-based Graviton, with local NVMe disks)<br/>- Enable disk setup when using instance types with local storage | `list(string)` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to the node group. | `map(string)` | `{}` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of worker nodes. | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of worker nodes. | `number` | `1` | no |
| <a name="input_node_group_name"></a> [node\_group\_name](#input\_node\_group\_name) | Name of the node group. | `string` | n/a | yes |
| <a name="input_node_taints"></a> [node\_taints](#input\_node\_taints) | Taints to apply to the node group. | <pre>list(object({<br/>    key    = string<br/>    value  = string<br/>    effect = string<br/>  }))</pre> | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the node group. | `list(string)` | n/a | yes |
| <a name="input_swap_enabled"></a> [swap\_enabled](#input\_swap\_enabled) | Whether to enable swap on the local NVMe disks. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node_group_arn"></a> [node\_group\_arn](#output\_node\_group\_arn) | ARN of the EKS managed node group. |
| <a name="output_node_group_id"></a> [node\_group\_id](#output\_node\_group\_id) | ID of the EKS managed node group. |
