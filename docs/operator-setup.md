# Installing the Materialize Operator

After deploying the infrastructure using this Terraform module, follow these steps to install the Materialize Operator on your EKS cluster.

## Prerequisites

- `kubectl` configured to interact with your EKS cluster
- Helm 3.2.0+
- AWS CLI configured with appropriate credentials

## Configure kubectl

First, update your kubeconfig to connect to the newly created EKS cluster:

```bash
aws eks update-kubeconfig --name materialize-cluster --region <your-region>
```

> Note: the exact authentication method may vary depending on your EKS configuration. For example, you might have to add an IAM access entry to the EKS cluster.

Verify the connection:

```bash
kubectl get nodes
```

## Install the Materialize Operator

The Materialize Operator is installed automatically when you set the following in your Terraform configuration:

```hcl
# Enable and configure Materialize Operator
install_materialize_operator = true
```

This eliminates the need to manually install the operator via Helm. Make sure that this setting is enabled in your Terraform configuration before applying changes:

```bash
terraform apply
```

You can verify that the Materialize Operator is installed by running:

```bash
kubectl get pods -n materialize
```

For more details on installation and configuration, refer to the official Materialize documentation: [Materialize AWS Installation Guide](https://materialize.com/docs/self-managed/v25.1/installation/install-on-aws/).

Alternatively, you can still install the [operator manually using Helm](https://github.com/MaterializeInc/materialize/tree/main/misc/helm-charts/operator#installing-the-chart).

## Deploying Materialize Environments

Once the infrastructure and the Materialize Operator are installed, you can deploy Materialize environments by setting the `materialize_instances` variable in your Terraform configuration.

1. Define your Materialize instances in `terraform.tfvars`:

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
       cpu_request    = "2"
       memory_request = "4Gi"
       memory_limit   = "4Gi"
     }
   ]
   ```

2. Re-apply the Terraform configuration to deploy the Materialize environments:

   ```bash
   terraform apply
   ```

Alternatively, you can manually deploy Materialize instances as described in the [Materialize Operator Helm Chart Documentation](https://github.com/MaterializeInc/materialize/tree/main/misc/helm-charts/operator#installing-the-chart).

You can check the status of the Materialize instances by running:

```bash
kubectl get pods -n materialize-environment
```

## Troubleshooting

If you encounter issues:

1. Check operator logs:
```bash
kubectl logs -l app.kubernetes.io/name=materialize-operator -n materialize
```

2. Check environment logs:
```bash
kubectl logs -l app.kubernetes.io/name=environmentd -n materialize-environment
```

3. Verify the storage configuration:
```bash
kubectl get sc
kubectl get pv
kubectl get pvc -A
```

## Cleanup

Delete the Materialize environment:
```bash
kubectl delete -f materialize-environment.yaml
```

To uninstall the Materialize operator:
```bash
terraform destroy
```

This will remove all associated resources, including the operator and any deployed Materialize instances.

For more details, visit the [Materialize documentation](https://materialize.com/docs/self-managed/v25.1/installation/install-on-aws/).
