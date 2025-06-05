# Materialize on AWS Terraform Modules

This repository provides a set of reusable, **self-contained Terraform modules** to deploy Materialize on the AWS cloud platform. You can use these modules individually or combine them to create your own custom infrastructure stack.

> **Note**
> These modules are intended for demonstration and prototyping purposes. If you're planning to use them in production, fork the repo and pin to a specific commit or tag to avoid breaking changes in future versions.

---

## Modular Architecture

Each module is designed to be used independently. You can compose them in any way that fits your use case.

See [`examples/simple/`](./examples/simple/) for a working example that ties the modules together into a complete environment.

---

## Available Modules

| Module                                                           | Description                                                           |
|------------------------------------------------------------------|-----------------------------------------------------------------------|
| [`modules/networking`](./modules/networking)                     | VPC, subnets, NAT gateways, and basic networking resources            |
| [`modules/eks`](./modules/eks)                                   | EKS cluster setup                                                     |
| [`modules/eks-node-group`](./modules/eks-node-group)             | EKS managed node groups with disk configuration                       |
| [`modules/database`](./modules/database)                         | RDS PostgreSQL database for Materialize metadata                      |
| [`modules/storage`](./modules/storage)                           | S3 bucket for Materialize persistence backend                         |
| [`modules/aws-lbc`](./modules/aws-lbc)                           | AWS Load Balancer Controller setup for NLBs                           |
| [`modules/openebs`](./modules/openebs)                           | OpenEBS setup for persistent volume storage using NVMe instance disks |
| [`modules/certificates`](./modules/certificates)                 | cert-manager installation and TLS management                          |
| [`modules/operator`](./modules/operator)                         | Materialize Kubernetes operator installation                          |
| [`modules/materialize-instance`](./modules/materialize-instance) | Materialize instance configuration and deployment                     |
| [`modules/nlb`](./modules/nlb)                                   | Network Load Balancer for Materialize instance access                 |

Depending on your needs, you can use the modules individually or combine them to create a setup that fits your needs.

---

## Getting Started

### Example Deployment

To deploy a simple end-to-end environment, see the [`examples/simple`](./examples/simple) folder.

```hcl
module "networking" {
  source = "../../modules/networking"
  name_prefix = "mz"
  # ... networking vars
}

module "eks" {
  source = "../../modules/eks"
  name_prefix = "mz"
  vpc_id = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  # ... eks vars
}

# See full working setup in the examples/simple/main.tf file
````

### Providers

Ensure you configure the AWS, Kubernetes, and Helm providers. Here's a minimal setup:

```hcl
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

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

---

## Local Development & Linting

Run this to format and generate docs across all modules:

```bash
.github/scripts/generate-docs.sh
```

Make sure `terraform-docs` and `tflint` are installed locally.
