# Example: Simple Materialize Deployment on AWS

This example demonstrates how to deploy a complete Materialize environment on AWS using the modular Terraform setup from this repository.

It provisions the full infrastructure stack, including:
- VPC and networking
- EKS cluster and node group
- RDS PostgreSQL for metadata
- S3 for persistent storage
- Load Balancer Controller and cert-manager
- Materialize operator

> **Important:**
> Due to a limitation with the `kubernetes_manifest` resource in Terraform, the Materialize instance **cannot be installed on the first run**. The Kubernetes cluster must be fully provisioned before applying the instance configuration.

---

## Getting Started

### Step 1: Set Required Variables

Before running Terraform, create a `terraform.tfvars` file or pass the following variables:

```hcl
name_prefix = "simple-demo"
install_materialize_instance = false
````

---

### Step 2: Deploy the Infrastructure

Run the usual Terraform workflow:

```bash
terraform init
terraform apply
```

This will provision all infrastructure components except the Materialize instance.

---

### Step 3: Deploy the Materialize Instance

Once the initial deployment completes successfully:

1. Update your variable:

   ```hcl
   install_materialize_instance = true
   ```

2. Run `terraform apply` again to deploy the instance.

---

## Notes

* You can customize each module independently.
* To reduce cost in your demo environment, you can tweak subnet CIDRs and instance types in `main.tf`.
* Don't forget to destroy resources when finished:

```bash
terraform destroy
```
