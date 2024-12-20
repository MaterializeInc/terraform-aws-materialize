<!-- BEGIN_TF_DOCS -->
# Materialize on AWS Cloud Platform

Terraform module for deploying Materialize on AWS Cloud Platform with all required infrastructure components.

> **Warning** This is provided on a best-effort basis and Materialize cannot offer support for this module.

The module has been tested with:
- PostgreSQL 15
- Materialize Operator v0.1.0

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.81.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ./modules/storage | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.materialize](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_access_key.materialize_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_role.materialize_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.materialize_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_user.materialize](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.materialize_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones | `list(string)` | <pre>[<br/>  "us-east-1a",<br/>  "us-east-1b",<br/>  "us-east-1c"<br/>]</pre> | no |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | Enable force destroy for the S3 bucket | `bool` | `false` | no |
| <a name="input_bucket_lifecycle_rules"></a> [bucket\_lifecycle\_rules](#input\_bucket\_lifecycle\_rules) | List of lifecycle rules for the S3 bucket | <pre>list(object({<br/>    id                                 = string<br/>    enabled                            = bool<br/>    prefix                             = string<br/>    transition_days                    = number<br/>    transition_storage_class           = string<br/>    expiration_days                    = number<br/>    noncurrent_version_expiration_days = number<br/>  }))</pre> | <pre>[<br/>  {<br/>    "enabled": true,<br/>    "expiration_days": 365,<br/>    "id": "cleanup",<br/>    "noncurrent_version_expiration_days": 90,<br/>    "prefix": "",<br/>    "transition_days": 90,<br/>    "transition_storage_class": "STANDARD_IA"<br/>  }<br/>]</pre> | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket | `string` | n/a | yes |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | List of desired control plane logging to enable | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | `"materialize-cluster"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version for the EKS cluster | `string` | `"1.31"` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Controls if VPC should be created (it affects almost all resources) | `bool` | `true` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the database to create | `string` | `"materialize"` | no |
| <a name="input_database_password"></a> [database\_password](#input\_database\_password) | Password for the database (should be provided via tfvars or environment variable) | `string` | n/a | yes |
| <a name="input_database_username"></a> [database\_username](#input\_database\_username) | Username for the database | `string` | `"materialize"` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | Allocated storage for the RDS instance (in GB) | `number` | `20` | no |
| <a name="input_db_identifier"></a> [db\_identifier](#input\_db\_identifier) | Identifier for the RDS instance | `string` | `"materialize-db"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | Instance class for the RDS instance | `string` | `"db.t3.large"` | no |
| <a name="input_db_max_allocated_storage"></a> [db\_max\_allocated\_storage](#input\_db\_max\_allocated\_storage) | Maximum storage for autoscaling (in GB) | `number` | `100` | no |
| <a name="input_db_multi_az"></a> [db\_multi\_az](#input\_db\_multi\_az) | Enable multi-AZ deployment for RDS | `bool` | `false` | no |
| <a name="input_enable_bucket_encryption"></a> [enable\_bucket\_encryption](#input\_enable\_bucket\_encryption) | Enable server-side encryption for the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_bucket_versioning"></a> [enable\_bucket\_versioning](#input\_enable\_bucket\_versioning) | Enable versioning for the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_cluster_creator_admin_permissions"></a> [enable\_cluster\_creator\_admin\_permissions](#input\_enable\_cluster\_creator\_admin\_permissions) | To add the current caller identity as an administrator | `bool` | `true` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable CloudWatch monitoring | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., prod, staging, dev) | `string` | `"dev"` | no |
| <a name="input_log_group_name_prefix"></a> [log\_group\_name\_prefix](#input\_log\_group\_name\_prefix) | Prefix for the CloudWatch log group name (will be combined with environment name) | `string` | `"materialize"` | no |
| <a name="input_metrics_retention_days"></a> [metrics\_retention\_days](#input\_metrics\_retention\_days) | Number of days to retain CloudWatch metrics | `number` | `7` | no |
| <a name="input_mz_iam_policy_name"></a> [mz\_iam\_policy\_name](#input\_mz\_iam\_policy\_name) | Name of the IAM policy for Materialize S3 access | `string` | `"materialize-s3-access"` | no |
| <a name="input_mz_iam_role_name"></a> [mz\_iam\_role\_name](#input\_mz\_iam\_role\_name) | Name of the IAM role for Materialize S3 access (will be prefixed with environment name) | `string` | `"materialize-s3-role"` | no |
| <a name="input_mz_iam_service_account_name"></a> [mz\_iam\_service\_account\_name](#input\_mz\_iam\_service\_account\_name) | Name of the IAM user for Materialize service authentication (will be prefixed with environment name) | `string` | `"materialize-user"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for Materialize resources | `string` | `"materialize-environment"` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | The ID of the VPC in which resources will be deployed. Only used if create\_vpc is false. | `string` | `""` | no |
| <a name="input_network_private_subnet_ids"></a> [network\_private\_subnet\_ids](#input\_network\_private\_subnet\_ids) | A list of private subnet IDs in the VPC. Only used if create\_vpc is false. | `list(string)` | `[]` | no |
| <a name="input_node_group_ami_type"></a> [node\_group\_ami\_type](#input\_node\_group\_ami\_type) | AMI type for the node group | `string` | `"AL2023_x86_64_STANDARD"` | no |
| <a name="input_node_group_capacity_type"></a> [node\_group\_capacity\_type](#input\_node\_group\_capacity\_type) | Capacity type for worker nodes (ON\_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| <a name="input_node_group_desired_size"></a> [node\_group\_desired\_size](#input\_node\_group\_desired\_size) | Desired number of worker nodes | `number` | `2` | no |
| <a name="input_node_group_instance_types"></a> [node\_group\_instance\_types](#input\_node\_group\_instance\_types) | Instance types for worker nodes.<br/><br/>Recommended Configuration for Running Materialize with disk:<br/>- Tested instance types: `m6g`, `m7g` families (ARM-based Graviton instances)<br/>- AMI: AWS Bottlerocket (optimized for container workloads)<br/>- Note: Ensure instance store volumes are available and attached to the nodes for optimal performance with disk-based workloads. | `list(string)` | <pre>[<br/>  "m6g.medium"<br/>]</pre> | no |
| <a name="input_node_group_max_size"></a> [node\_group\_max\_size](#input\_node\_group\_max\_size) | Maximum number of worker nodes | `number` | `4` | no |
| <a name="input_node_group_min_size"></a> [node\_group\_min\_size](#input\_node\_group\_min\_size) | Minimum number of worker nodes | `number` | `1` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | Version of PostgreSQL to use | `string` | `"15"` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | CIDR blocks for private subnets | `list(string)` | <pre>[<br/>  "10.0.1.0/24",<br/>  "10.0.2.0/24",<br/>  "10.0.3.0/24"<br/>]</pre> | no |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | CIDR blocks for public subnets | `list(string)` | <pre>[<br/>  "10.0.101.0/24",<br/>  "10.0.102.0/24",<br/>  "10.0.103.0/24"<br/>]</pre> | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name of the service account | `string` | `"12345678-1234-1234-1234-123456789012"` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Use a single NAT Gateway for all private subnets | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags to apply to all resources | `map(string)` | <pre>{<br/>  "Environment": "dev",<br/>  "Project": "materialize",<br/>  "Terraform": "true"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of the VPC | `string` | `"materialize-vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_endpoint"></a> [database\_endpoint](#output\_database\_endpoint) | RDS instance endpoint |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | EKS cluster endpoint |
| <a name="output_materialize_s3_role_arn"></a> [materialize\_s3\_role\_arn](#output\_materialize\_s3\_role\_arn) | The ARN of the IAM role for Materialize |
| <a name="output_metadata_backend_url"></a> [metadata\_backend\_url](#output\_metadata\_backend\_url) | PostgreSQL connection URL in the format required by Materialize |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider |
| <a name="output_persist_backend_url"></a> [persist\_backend\_url](#output\_persist\_backend\_url) | S3 connection URL in the format required by Materialize using IRSA |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |

## Post-Deployment Setup

After successfully deploying the infrastructure with this module, you'll need to:

1. (Optional) Configure storage classes
1. Install the [Materialize Operator](https://github.com/MaterializeInc/materialize/tree/main/misc/helm-charts/operator)
1. Deploy your first Materialize environment

See our [Operator Installation Guide](docs/operator-setup.md) for instructions.
<!-- END_TF_DOCS -->
