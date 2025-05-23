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

## Architecture Overview

This module creates a complete AWS infrastructure stack for running Materialize, including:

- **Networking**: VPC, subnets, NAT gateways, and security groups
- **Compute**: EKS cluster with managed node groups
- **Storage**: RDS PostgreSQL for metadata and S3 for persistent data
- **Load Balancing**: AWS Load Balancer Controller for Network Load Balancers
- **Storage Classes**: OpenEBS for Kubernetes persistent volumes
- **TLS/Certificates**: cert-manager for TLS certificate management
- **Materialize Operator**: Kubernetes operator for managing Materialize instances

## Providers Configuration

The module requires the following providers to be configured:

```hcl
provider "aws" {
  region = var.aws_region
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

## Usage

### Basic Usage

```hcl
module "materialize_platform" {
  source = "path/to/this/module"

  # Basic configuration
  name_prefix  = "my-materialize"
  aws_region   = "us-east-1"

  # After the infrastructure is deployed, you can deploy a Materialize instance
  # by setting this to true
  install_materialize_instance = false
}
```

## Modular Architecture

This module is built using a modular architecture, allowing you to use individual components if needed:

```hcl
# Use individual modules for more control
module "networking" {
  source = "./modules/networking"
  # ... configuration
}

module "eks" {
  source = "./modules/eks"
  # ... configuration
}

module "materialize_instance" {
  source = "./modules/materialize-instance"

  instance_name        = "main"
  instance_namespace   = "materialize-main"
  metadata_backend_url = "postgres://..."
  persist_backend_url  = "s3://..."

  # Infrastructure references
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  # ... other config
}
```

## Available Modules

The following individual modules are available:

- `modules/networking` - VPC, subnets, and networking components
- `modules/eks` - EKS cluster configuration
- `modules/eks-node-group` - EKS managed node groups
- `modules/database` - RDS PostgreSQL for metadata storage
- `modules/storage` - S3 bucket for persistent data
- `modules/aws-lbc` - AWS Load Balancer Controller
- `modules/openebs` - OpenEBS storage classes
- `modules/certificates` - cert-manager for TLS
- `modules/operator` - Materialize Kubernetes operator
- `modules/materialize-instance` - Individual Materialize instances
- `modules/nlb` - Network Load Balancer for instances

## Disk Support for Materialize

This module supports configuring disk support for Materialize using NVMe instance storage and OpenEBS.

When using disk support, you need to use instance types from the `r7gd` or `r6gd` family or other instance types with NVMe instance storage.

### Enabling Disk Support

Disk support is enabled by default when using compatible instance types. The module automatically:

1. Installs OpenEBS via Helm
2. Configures NVMe instance store volumes using the bootstrap script
3. Creates appropriate storage classes for Materialize
4. Labels nodes with `materialize.cloud/disk = "true"`

### Node Group Configuration

```hcl
# Example with disk-enabled instances
node_group_instance_types = ["r7gd.xlarge"]  # Has NVMe storage
node_group_labels = {
  "materialize.cloud/disk" = "true"
  "workload"               = "materialize-instance"
}
```
