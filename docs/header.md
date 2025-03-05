# Materialize on AWS Cloud Platform

Terraform module for deploying Materialize on AWS Cloud Platform with all required infrastructure components.

> **Warning** This is provided on a best-effort basis and Materialize cannot offer support for this module.

The module has been tested with:
- PostgreSQL 15
- Materialize Helm Operator Terraform Module v0.1.1

## Providers Configuration

The module requires the following providers to be configured:

```hcl
provider "aws" {
  region = "us-east-1"
  # Other AWS provider configuration as needed
}

# Required for EKS authentication
provider "kubernetes" {
  host                   = module.materialize_infrastructure.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.materialize_infrastructure.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.materialize_infrastructure.eks_cluster_name]
    command     = "aws"
  }
}

# Required for Materialize Operator installation
provider "helm" {
  kubernetes {
    host                   = module.materialize_infrastructure.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.materialize_infrastructure.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.materialize_infrastructure.eks_cluster_name]
      command     = "aws"
    }
  }
}

module "materialize_infrastructure" {
  source = "git::https://github.com/MaterializeInc/terraform-aws-materialize.git"
  # Other required variables
}
```

> **Note:** The Kubernetes and Helm providers are configured to use the AWS CLI for authentication with the EKS cluster. This requires that you have the AWS CLI installed and configured with access to the AWS account where the EKS cluster is deployed.

You can also set the `AWS_PROFILE` environment variable to the name of the profile you want to use for authentication with the EKS cluster:

```bash
export AWS_PROFILE=your-profile-name
```
