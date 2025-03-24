# Materialize on AWS Cloud Platform

Terraform module for deploying Materialize on AWS Cloud Platform with all required infrastructure components.

The module has been tested with:

- PostgreSQL 15
- Materialize Helm Operator Terraform Module v0.1.8

> [!WARNING]
> This module is provided on a best-effort basis and Materialize cannot offer support for it.
>
> It is not guaranteed to be forward-compatible and may include breaking changes in future versions.
>
> The module is intended for demonstration and evaluation purposes only, not for production use.
>
> Instead, consider forking this repository as a starting point for building your own production infrastructure.

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
  openebs_version = "4.2.0"
  storage_class_name = "custom-storage-class"
  storage_class_parameters = {
    volgroup = "custom-volume-group"
  }
}
```
