<!-- BEGIN_TF_DOCS -->
# Materialize on AWS Cloud Platform

Terraform module for deploying Materialize on AWS Cloud Platform with all required infrastructure components.

The module has been tested with:

- PostgreSQL 15
- Materialize Helm Operator Terraform Module v0.1.12

> [!WARNING]
> This module is intended for demonstration/evaluation purposes as well as for serving as a template when building your own production deployment of Materialize.
>
> This module should not be directly relied upon for production deployments: **future releases of the module will contain breaking changes.** Instead, to use as a starting point for your own production deployment, either:
> - Fork this repo and pin to a specific version, or
> - Use the code as a reference when developing your own deployment.

## Providers Configuration

The module requires the following providers to be configured:

```hcl
provider "aws" {
  region = "us-east-1"
  # Other AWS provider configuration as needed
}

# Required for EKS authentication
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

# Required for Materialize Operator installation
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

```

> **Note:** The Kubernetes and Helm providers are configured to use the AWS CLI for authentication with the EKS cluster. This requires that you have the AWS CLI installed and configured with access to the AWS account where the EKS cluster is deployed.

You can also set the `AWS_PROFILE` environment variable to the name of the profile you want to use for authentication with the EKS cluster:

```bash
export AWS_PROFILE=your-profile-name
```

## Disk Support for Materialize

This module supports configuring disk support for Materialize using NVMe instance storage and OpenEBS and lgalloc.

When using disk support, you need to use instance types from the `r7gd` or `r6gd` family or other instance types with NVMe instance storage.

### Enabling Disk Support

To enable disk support with default settings:

```hcl
enable_disk_support = true
```

This will:
1. Install OpenEBS via Helm
2. Configure NVMe instance store volumes using the bootstrap script
3. Create appropriate storage classes for Materialize

### Advanced Configuration

In case that you need more control over the disk setup:

```hcl
enable_disk_support = true

disk_support_config = {
  openebs_version = "4.3.3"
  storage_class_name = "custom-storage-class"
  storage_class_parameters = {
    volgroup = "custom-volume-group"
  }
}
```

## `materialize_instances` variable

The `materialize_instances` variable is a list of objects that define the configuration for each Materialize instance.

### `environmentd_extra_args`

Optional list of additional command-line arguments to pass to the `environmentd` container. This can be used to override default system parameters or enable specific features.

```hcl
environmentd_extra_args = [
  "--system-parameter-default=max_clusters=1000",
  "--system-parameter-default=max_connections=1000",
  "--system-parameter-default=max_tables=1000",
]
```

These flags configure default limits for clusters, connections, and tables. You can provide any supported arguments [here](https://materialize.com/docs/sql/alter-system-set/#other-configuration-parameters).

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_deepmerge"></a> [deepmerge](#requirement\_deepmerge) | ~> 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_lbc"></a> [aws\_lbc](#module\_aws\_lbc) | ./modules/aws-lbc | n/a |
| <a name="module_certificates"></a> [certificates](#module\_certificates) | ./modules/certificates | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_nlb"></a> [nlb](#module\_nlb) | ./modules/nlb | n/a |
| <a name="module_operator"></a> [operator](#module\_operator) | github.com/MaterializeInc/terraform-helm-materialize | v0.1.31 |
| <a name="module_storage"></a> [storage](#module\_storage) | ./modules/storage | n/a |
| <a name="module_swap_node_group"></a> [swap\_node\_group](#module\_swap\_node\_group) | ./modules/eks-node-group | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.materialize](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.materialize_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.materialize_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones | `list(string)` | <pre>[<br/>  "us-east-1a",<br/>  "us-east-1b",<br/>  "us-east-1c"<br/>]</pre> | no |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | Enable force destroy for the S3 bucket | `bool` | `true` | no |
| <a name="input_bucket_lifecycle_rules"></a> [bucket\_lifecycle\_rules](#input\_bucket\_lifecycle\_rules) | List of lifecycle rules for the S3 bucket | <pre>list(object({<br/>    id                                 = string<br/>    enabled                            = bool<br/>    prefix                             = string<br/>    transition_days                    = number<br/>    transition_storage_class           = string<br/>    noncurrent_version_expiration_days = number<br/>  }))</pre> | <pre>[<br/>  {<br/>    "enabled": true,<br/>    "id": "cleanup",<br/>    "noncurrent_version_expiration_days": 90,<br/>    "prefix": "",<br/>    "transition_days": 90,<br/>    "transition_storage_class": "STANDARD_IA"<br/>  }<br/>]</pre> | no |
| <a name="input_cert_manager_chart_version"></a> [cert\_manager\_chart\_version](#input\_cert\_manager\_chart\_version) | Version of the cert-manager helm chart to install. | `string` | `"v1.17.1"` | no |
| <a name="input_cert_manager_install_timeout"></a> [cert\_manager\_install\_timeout](#input\_cert\_manager\_install\_timeout) | Timeout for installing the cert-manager helm chart, in seconds. | `number` | `300` | no |
| <a name="input_cert_manager_namespace"></a> [cert\_manager\_namespace](#input\_cert\_manager\_namespace) | The name of the namespace in which cert-manager is or will be installed. | `string` | `"cert-manager"` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | List of desired control plane logging to enable | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version for the EKS cluster | `string` | `"1.32"` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Controls if VPC should be created (it affects almost all resources) | `bool` | `true` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the database to create | `string` | `"materialize"` | no |
| <a name="input_database_password"></a> [database\_password](#input\_database\_password) | Password for the database (should be provided via tfvars or environment variable) | `string` | n/a | yes |
| <a name="input_database_username"></a> [database\_username](#input\_database\_username) | Username for the database | `string` | `"materialize"` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | Allocated storage for the RDS instance (in GB) | `number` | `20` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | Instance class for the RDS instance. This is used for concensus and metadata and is general not bottlnecked by memory or disk. Recomended instance family m7i, m6i, m7g, and m8g | `string` | `"db.m6i.large"` | no |
| <a name="input_db_max_allocated_storage"></a> [db\_max\_allocated\_storage](#input\_db\_max\_allocated\_storage) | Maximum storage for autoscaling (in GB) | `number` | `100` | no |
| <a name="input_db_multi_az"></a> [db\_multi\_az](#input\_db\_multi\_az) | Enable multi-AZ deployment for RDS | `bool` | `false` | no |
| <a name="input_disk_support_config"></a> [disk\_support\_config](#input\_disk\_support\_config) | Advanced configuration for disk support (only used when enable\_disk\_support = true) | <pre>object({<br/>    install_openebs           = optional(bool, true)<br/>    run_disk_setup_script     = optional(bool, true)<br/>    create_storage_class      = optional(bool, true)<br/>    openebs_version           = optional(string, "4.3.3")<br/>    openebs_namespace         = optional(string, "openebs")<br/>    storage_class_name        = optional(string, "openebs-lvm-instance-store-ext4")<br/>    storage_class_provisioner = optional(string, "local.csi.openebs.io")<br/>    storage_class_parameters = optional(object({<br/>      storage  = optional(string, "lvm")<br/>      fsType   = optional(string, "ext4")<br/>      volgroup = optional(string, "instance-store-vg")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_enable_bucket_encryption"></a> [enable\_bucket\_encryption](#input\_enable\_bucket\_encryption) | Enable server-side encryption for the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_bucket_versioning"></a> [enable\_bucket\_versioning](#input\_enable\_bucket\_versioning) | Enable versioning for the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_cluster_creator_admin_permissions"></a> [enable\_cluster\_creator\_admin\_permissions](#input\_enable\_cluster\_creator\_admin\_permissions) | To add the current caller identity as an administrator | `bool` | `true` | no |
| <a name="input_enable_disk_support"></a> [enable\_disk\_support](#input\_enable\_disk\_support) | Enable disk support for Materialize using OpenEBS and NVMe instance storage. When enabled, this configures OpenEBS, runs the disk setup script for NVMe devices, and creates appropriate storage classes. | `bool` | `true` | no |
| <a name="input_enable_monitoring"></a> [enable\_monitoring](#input\_enable\_monitoring) | Enable CloudWatch monitoring | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., prod, staging, dev) | `string` | n/a | yes |
| <a name="input_helm_chart"></a> [helm\_chart](#input\_helm\_chart) | Chart name from repository or local path to chart. For local charts, set the path to the chart directory. | `string` | `"materialize-operator"` | no |
| <a name="input_helm_values"></a> [helm\_values](#input\_helm\_values) | Additional Helm values to merge with defaults | `any` | `{}` | no |
| <a name="input_install_aws_load_balancer_controller"></a> [install\_aws\_load\_balancer\_controller](#input\_install\_aws\_load\_balancer\_controller) | Whether to install the AWS Load Balancer Controller | `bool` | `true` | no |
| <a name="input_install_cert_manager"></a> [install\_cert\_manager](#input\_install\_cert\_manager) | Whether to install cert-manager. | `bool` | `true` | no |
| <a name="input_install_materialize_operator"></a> [install\_materialize\_operator](#input\_install\_materialize\_operator) | Whether to install the Materialize operator | `bool` | `true` | no |
| <a name="input_install_metrics_server"></a> [install\_metrics\_server](#input\_install\_metrics\_server) | Whether to install the metrics-server for the Materialize Console | `bool` | `true` | no |
| <a name="input_kubernetes_namespace"></a> [kubernetes\_namespace](#input\_kubernetes\_namespace) | The Kubernetes namespace for the Materialize resources | `string` | `"materialize-environment"` | no |
| <a name="input_log_group_name_prefix"></a> [log\_group\_name\_prefix](#input\_log\_group\_name\_prefix) | Prefix for the CloudWatch log group name (will be combined with environment name) | `string` | `"materialize"` | no |
| <a name="input_materialize_instances"></a> [materialize\_instances](#input\_materialize\_instances) | Configuration for Materialize instances. Due to limitations in Terraform, `materialize_instances` cannot be defined on the first `terraform apply`. | <pre>list(object({<br/>    name                              = string<br/>    namespace                         = optional(string)<br/>    database_name                     = string<br/>    environmentd_version              = optional(string)<br/>    cpu_request                       = optional(string, "1")<br/>    memory_request                    = optional(string, "1Gi")<br/>    memory_limit                      = optional(string, "1Gi")<br/>    create_database                   = optional(bool, true)<br/>    create_nlb                        = optional(bool, true)<br/>    internal_nlb                      = optional(bool, true)<br/>    enable_cross_zone_load_balancing  = optional(bool, true)<br/>    in_place_rollout                  = optional(bool, false)<br/>    request_rollout                   = optional(string)<br/>    force_rollout                     = optional(string)<br/>    balancer_memory_request           = optional(string, "256Mi")<br/>    balancer_memory_limit             = optional(string, "256Mi")<br/>    balancer_cpu_request              = optional(string, "100m")<br/>    license_key                       = optional(string)<br/>    authenticator_kind                = optional(string, "None")<br/>    external_login_password_mz_system = optional(string)<br/>    environmentd_extra_args           = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_metrics_retention_days"></a> [metrics\_retention\_days](#input\_metrics\_retention\_days) | Number of days to retain CloudWatch metrics | `number` | `7` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for all resources, usually the organization or project name | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | The ID of the VPC in which resources will be deployed. Only used if create\_vpc is false. | `string` | `""` | no |
| <a name="input_network_private_subnet_ids"></a> [network\_private\_subnet\_ids](#input\_network\_private\_subnet\_ids) | A list of private subnet IDs in the VPC. Only used if create\_vpc is false. | `list(string)` | `[]` | no |
| <a name="input_network_public_subnet_ids"></a> [network\_public\_subnet\_ids](#input\_network\_public\_subnet\_ids) | A list of public subnet IDs in the VPC. Only used if create\_vpc is false. | `list(string)` | `[]` | no |
| <a name="input_node_group_ami_type"></a> [node\_group\_ami\_type](#input\_node\_group\_ami\_type) | AMI type for the node group | `string` | `"AL2023_ARM_64_STANDARD"` | no |
| <a name="input_node_group_capacity_type"></a> [node\_group\_capacity\_type](#input\_node\_group\_capacity\_type) | Capacity type for worker nodes (ON\_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| <a name="input_node_group_desired_size"></a> [node\_group\_desired\_size](#input\_node\_group\_desired\_size) | Desired number of worker nodes | `number` | `2` | no |
| <a name="input_node_group_instance_types"></a> [node\_group\_instance\_types](#input\_node\_group\_instance\_types) | Instance types for worker nodes.<br/><br/>Recommended Configuration for Running Materialize with disk:<br/>- Tested instance types: `r6gd`, `r7gd` families (ARM-based Graviton instances)<br/>- Enable disk setup when using `r7gd`<br/>- Note: Ensure instance store volumes are available and attached to the nodes for optimal performance with disk-based workloads. | `list(string)` | <pre>[<br/>  "r7gd.2xlarge"<br/>]</pre> | no |
| <a name="input_node_group_max_size"></a> [node\_group\_max\_size](#input\_node\_group\_max\_size) | Maximum number of worker nodes | `number` | `4` | no |
| <a name="input_node_group_min_size"></a> [node\_group\_min\_size](#input\_node\_group\_min\_size) | Minimum number of worker nodes | `number` | `1` | no |
| <a name="input_operator_namespace"></a> [operator\_namespace](#input\_operator\_namespace) | Namespace for the Materialize operator | `string` | `"materialize"` | no |
| <a name="input_operator_version"></a> [operator\_version](#input\_operator\_version) | Version of the Materialize operator to install | `string` | `null` | no |
| <a name="input_orchestratord_version"></a> [orchestratord\_version](#input\_orchestratord\_version) | Version of the Materialize orchestrator to install | `string` | `null` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | Version of PostgreSQL to use | `string` | `"17"` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | CIDR blocks for private subnets | `list(string)` | <pre>[<br/>  "10.0.1.0/24",<br/>  "10.0.2.0/24",<br/>  "10.0.3.0/24"<br/>]</pre> | no |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | CIDR blocks for public subnets | `list(string)` | <pre>[<br/>  "10.0.101.0/24",<br/>  "10.0.102.0/24",<br/>  "10.0.103.0/24"<br/>]</pre> | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name of the service account | `string` | `"12345678-1234-1234-1234-123456789012"` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Use a single NAT Gateway for all private subnets | `bool` | `false` | no |
| <a name="input_swap_enabled"></a> [swap\_enabled](#input\_swap\_enabled) | Enable swap for Materialize. When enabled, this configures swap on a new nodepool, and adds it to the clusterd node selectors. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags to apply to all resources | `map(string)` | <pre>{<br/>  "Environment": "dev",<br/>  "Project": "materialize",<br/>  "Terraform": "true"<br/>}</pre> | no |
| <a name="input_use_local_chart"></a> [use\_local\_chart](#input\_use\_local\_chart) | Whether to use a local chart instead of one from a repository | `bool` | `false` | no |
| <a name="input_use_self_signed_cluster_issuer"></a> [use\_self\_signed\_cluster\_issuer](#input\_use\_self\_signed\_cluster\_issuer) | Whether to install and use a self-signed ClusterIssuer for TLS. To work around limitations in Terraform, this will be treated as `false` if no materialize instances are defined. | `bool` | `true` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_database_endpoint"></a> [database\_endpoint](#output\_database\_endpoint) | RDS instance endpoint |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | EKS cluster endpoint |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | EKS cluster name |
| <a name="output_materialize_s3_role_arn"></a> [materialize\_s3\_role\_arn](#output\_materialize\_s3\_role\_arn) | The ARN of the IAM role for Materialize |
| <a name="output_metadata_backend_url"></a> [metadata\_backend\_url](#output\_metadata\_backend\_url) | PostgreSQL connection URL in the format required by Materialize |
| <a name="output_nlb_details"></a> [nlb\_details](#output\_nlb\_details) | Details of the Materialize instance NLBs. |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider |
| <a name="output_operator_details"></a> [operator\_details](#output\_operator\_details) | Details of the installed Materialize operator |
| <a name="output_persist_backend_url"></a> [persist\_backend\_url](#output\_persist\_backend\_url) | S3 connection URL in the format required by Materialize using IRSA |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnet IDs |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |

## Post-Deployment Setup

After successfully deploying the infrastructure with this module, you'll need to:

1. (Optional) Configure storage classes
1. Install the [Materialize Operator](https://github.com/MaterializeInc/materialize/tree/main/misc/helm-charts/operator)
1. Deploy your first Materialize environment

See our [Operator Installation Guide](docs/operator-setup.md) for instructions.

## Connecting to Materialize instances

By default, Network Load Balancers are created for each Materialize instance, with three listeners:
1. Port 6875 for SQL connections to the database.
1. Port 6876 for HTTP(S) connections to the database.
1. Port 8080 for HTTP(S) connections to the web console.

The DNS name and ARN for the NLBs will be in the `terraform output` as `nlb_details`.

#### TLS support

TLS support is provided by using `cert-manager` and a self-signed `ClusterIssuer`.

More advanced TLS support using user-provided CAs or per-Materialize `Issuer`s are out of scope for this Terraform module. Please refer to the [cert-manager documentation](https://cert-manager.io/docs/configuration/) for detailed guidance on more advanced usage.

## Upgrade Notes

#### v0.6.1

We now have some initial support for swap.

To use swap:
1. Set `swap_enabled` to `true`.
2. Ensure your `environmentd_version` is at least `v26.0.0`.
3. Update your `request_rollout` (and `force_rollout` if already at the correct `environmentd_version`).
4. Run `terraform apply`.

This will create a new node group configured for swap, and migrate your clusterd pods there.

#### v0.6.0

This version is missing the updated helm chart.
Skip this version, go to v0.6.1.

#### v0.4.0
We now install `cert-manager` and configure a self-signed `ClusterIssuer` by default.

Due to limitations in Terraform, it cannot plan Kubernetes resources using CRDs that do not exist yet. We have worked around this for new users by only generating the certificate resources when creating Materialize instances that use them, which also cannot be created on the first run.

For existing users upgrading Materialize instances not previously configured for TLS:
1. Leave `install_cert_manager` at its default of `true`.
2. Set `use_self_signed_cluster_issuer` to `false`.
3. Run `terraform apply`. This will install cert-manager and its CRDs.
4. Set `use_self_signed_cluster_issuer` back to `true` (the default).
5. Update the `request_rollout` field of the Materialize instance.
6. Run `terraform apply`. This will generate the certificates and configure your Materialize instance to use them.

#### v0.3.0
We now install the AWS Load Balancer Controller and create Network Load Balancers for each Materialize instance.

If managing Materialize instances with this module, additional action may be required to upgrade to this version.

###### If you want to disable NLB support
* Set `install_aws_load_balancer_controller` to `false`.
* Set `materialize_instances[*].create_nlb` to `false`.

###### If you want to enable NLB support
* Leave `install_aws_load_balancer_controller` set to its default of `true`.
* Set `materialize_instances[*].create_nlb` to `false`.
* Run `terraform apply`.
* Set `materialize_instances[*].create_nlb` to `true`.
* Run `terraform apply`.

Due to limitations in Terraform, it cannot plan Kubernetes resources using CRDs that do not exist yet. We need to first install the AWS Load Balancer Controller in the first `terraform apply`, before defining any `TargetGroupBinding` resources which get created in the second `terraform apply`.
<!-- END_TF_DOCS -->
