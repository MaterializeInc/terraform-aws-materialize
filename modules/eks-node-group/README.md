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
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | AMI type for the node group. | `string` | `"AL2023_ARM_64_STANDARD"` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Capacity type for worker nodes (ON\_DEMAND or SPOT). | `string` | `"ON_DEMAND"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster to attach the node group to. | `string` | n/a | yes |
| <a name="input_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#input\_cluster\_primary\_security\_group\_id) | The ID of the primary security group for the cluster | `string` | n/a | yes |
| <a name="input_cluster_service_cidr"></a> [cluster\_service\_cidr](#input\_cluster\_service\_cidr) | The CIDR block for the cluster service | `string` | n/a | yes |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired number of worker nodes. | `number` | `1` | no |
| <a name="input_enable_disk_setup"></a> [enable\_disk\_setup](#input\_enable\_disk\_setup) | Whether to enable disk setup using the bootstrap script | `bool` | `true` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Instance types for worker nodes.<br/><br/>Recommended Configuration for Running Materialize with disk:<br/>- Tested instance types: `r6gd`, `r7gd` families (ARM-based Graviton instances)<br/>- Enable disk setup when using `r7gd`<br/>- Note: Ensure instance store volumes are available and attached to the nodes for optimal performance with disk-based workloads. | `list(string)` | <pre>[<br/>  "r7gd.2xlarge"<br/>]</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to the node group. | `map(string)` | `{}` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of worker nodes. | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of worker nodes. | `number` | `1` | no |
| <a name="input_node_group_name"></a> [node\_group\_name](#input\_node\_group\_name) | Name of the node group. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the node group. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node_group_arn"></a> [node\_group\_arn](#output\_node\_group\_arn) | ARN of the EKS managed node group. |
| <a name="output_node_group_id"></a> [node\_group\_id](#output\_node\_group\_id) | ID of the EKS managed node group. |
