## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.5.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.5.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.openebs](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.openebs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_openebs_namespace"></a> [create\_openebs\_namespace](#input\_create\_openebs\_namespace) | Whether to create the OpenEBS namespace. Set to false if the namespace already exists. | `bool` | `true` | no |
| <a name="input_openebs_namespace"></a> [openebs\_namespace](#input\_openebs\_namespace) | Namespace for OpenEBS components | `string` | `"openebs"` | no |
| <a name="input_openebs_version"></a> [openebs\_version](#input\_openebs\_version) | Version of OpenEBS Helm chart to install | `string` | `"4.2.0"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_openebs_namespace"></a> [openebs\_namespace](#output\_openebs\_namespace) | Namespace where OpenEBS is installed |
