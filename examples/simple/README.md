# Simple Example for Terraform AWS Materialize Module

This directory contains a simple example of using the [Terraform AWS Materialize module](https://github.com/MaterializeInc/terraform-aws-materialize/) to deploy a basic infrastructure setup.

## What This Example Does

- Creates a VPC.
- Provisions an EKS cluster with a basic node group.
- Sets up an RDS PostgreSQL instance.
- Creates an S3 bucket.
- Deploys the Materialize Operator.

## How to Use

1. Clone the repository:
   ```bash
   git clone https://github.com/MaterializeInc/terraform-aws-materialize.git
   cd terraform-aws-materialize/examples/simple
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Copy the `terraform.tfvars.example` file to `terraform.tfvars` and update the variables:
   ```hcl
   namespace = "example-namespace"
   environment = "dev"
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

5. Review the outputs for details such as the VPC ID, EKS cluster endpoint, and S3 bucket name.

## Example Configuration

This example uses the following variables:

- **namespace**: A prefix for resource names, e.g., `mz-demo-namespace`.
- **environment**: The deployment environment (e.g., `dev`, `staging`).

Refer to the `variables.tf` file for more details on available variables.

## Deploying Materialize Instances

Once the infrastructure and the Materialize Operator are installed, you can deploy Materialize instances by uncommenting and configuring the `materialize_instances` variable in your `terraform.tfvars` file.

1. Open the `terraform.tfvars` file and uncomment the `materialize_instances` block. Customize it as needed. For example:

   ```hcl
   materialize_instances = [
     {
       name           = "analytics"
       namespace      = "materialize-environment"
       database_name  = "analytics_db"
       cpu_request    = "2"
       memory_request = "4Gi"
       memory_limit   = "4Gi"
     },
     {
       name           = "demo"
       namespace      = "materialize-environment"
       database_name  = "demo_db"
       cpu_request    = "4"
       memory_request = "4Gi"
       memory_limit   = "4Gi"
     }
   ]
   ```

2. Re-apply the Terraform configuration to create the Materialize instances:
   ```bash
   terraform apply
   ```

This will deploy the necessary CRDs for the specified Materialize instances within your cluster. You can check the status of the Materialize instances by running:

```bash
kubectl get pods -n materialize-environment
```

## Cleaning Up

To destroy the resources created by this example, run:

```bash
terraform destroy
```
