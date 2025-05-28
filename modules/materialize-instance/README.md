## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_manifest.materialize_instance](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.instance](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.materialize_backend](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_resource.materialize_instance](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_balancer_cpu_request"></a> [balancer\_cpu\_request](#input\_balancer\_cpu\_request) | CPU request for balancer | `string` | `"100m"` | no |
| <a name="input_balancer_memory_limit"></a> [balancer\_memory\_limit](#input\_balancer\_memory\_limit) | Memory limit for balancer | `string` | `"256Mi"` | no |
| <a name="input_balancer_memory_request"></a> [balancer\_memory\_request](#input\_balancer\_memory\_request) | Memory request for balancer | `string` | `"256Mi"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | CPU request for environmentd | `string` | `"1"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create the Kubernetes namespace | `bool` | `true` | no |
| <a name="input_environmentd_extra_args"></a> [environmentd\_extra\_args](#input\_environmentd\_extra\_args) | Extra command line arguments for environmentd | `list(string)` | `[]` | no |
| <a name="input_environmentd_extra_env"></a> [environmentd\_extra\_env](#input\_environmentd\_extra\_env) | Extra environment variables for environmentd | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_environmentd_version"></a> [environmentd\_version](#input\_environmentd\_version) | Version of environmentd to use | `string` | `"v0.130.13"` | no |
| <a name="input_force_rollout"></a> [force\_rollout](#input\_force\_rollout) | UUID to force a rollout | `string` | `"00000000-0000-0000-0000-000000000001"` | no |
| <a name="input_in_place_rollout"></a> [in\_place\_rollout](#input\_in\_place\_rollout) | Whether to perform in-place rollouts | `bool` | `true` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the Materialize instance | `string` | n/a | yes |
| <a name="input_instance_namespace"></a> [instance\_namespace](#input\_instance\_namespace) | Kubernetes namespace for the instance. If not provided, will use operator\_namespace | `string` | `null` | no |
| <a name="input_license_key"></a> [license\_key](#input\_license\_key) | Materialize license key | `string` | `null` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | Memory limit for environmentd | `string` | `"1Gi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | Memory request for environmentd | `string` | `"1Gi"` | no |
| <a name="input_metadata_backend_url"></a> [metadata\_backend\_url](#input\_metadata\_backend\_url) | PostgreSQL connection URL for metadata backend | `string` | n/a | yes |
| <a name="input_operator_namespace"></a> [operator\_namespace](#input\_operator\_namespace) | Namespace where the operator is installed (used as fallback if instance\_namespace is not provided) | `string` | n/a | yes |
| <a name="input_persist_backend_url"></a> [persist\_backend\_url](#input\_persist\_backend\_url) | S3 connection URL for persist backend | `string` | n/a | yes |
| <a name="input_request_rollout"></a> [request\_rollout](#input\_request\_rollout) | UUID to request a rollout | `string` | `"00000000-0000-0000-0000-000000000001"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | Name of the Materialize instance |
| <a name="output_instance_namespace"></a> [instance\_namespace](#output\_instance\_namespace) | Namespace of the Materialize instance |
| <a name="output_instance_resource_id"></a> [instance\_resource\_id](#output\_instance\_resource\_id) | Resource ID of the Materialize instance |
| <a name="output_metadata_backend_url"></a> [metadata\_backend\_url](#output\_metadata\_backend\_url) | Metadata backend URL used by the Materialize instance |
| <a name="output_persist_backend_url"></a> [persist\_backend\_url](#output\_persist\_backend\_url) | Persist backend URL used by the Materialize instance |
