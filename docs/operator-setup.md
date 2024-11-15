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

## (Optional) Storage Configuration

The Materialize Operator requires fast, locally-attached NVMe storage for optimal performance. We'll set up OpenEBS with LVM Local PV for managing local volumes.

1. Install OpenEBS:
```bash
# Add the OpenEBS Helm repository
helm repo add openebs https://openebs.github.io/openebs
helm repo update

# Install OpenEBS with only Local PV enabled
helm install openebs --namespace openebs openebs/openebs \
  --set engines.replicated.mayastor.enabled=false \
  --create-namespace
```

2. Verify the installation:
```bash
kubectl get pods -n openebs -l role=openebs-lvm
```

### LVM Configuration for AWS Bottlerocket nodes

TODO: Add more detailed instructions for setting up LVM on Bottlerocket nodes.

If you're using the recommended Bottlerocket AMI with the Terraform module, the LVM configuration needs to be done through the Bottlerocket bootstrap container. This is automatically handled by the EKS module using the provided user data script.

To verify the LVM setup:
```bash
kubectl debug -it node/<node-name> --image=amazonlinux:2
chroot /host
lvs
```

You should see a volume group named `instance-store-vg`.

## Install the Materialize Operator

0. Clone the Materialize repository:
```bash
git@github.com:MaterializeInc/materialize.git
cd materialize
```

1. Create a values file for the Helm installation (save as `materialize-values.yaml`):
```yaml
operator:
  args:
    cloudProvider: "aws"
    region: "<your-aws-region>" # e.g. us-west-2
    localDevelopment: false
    awsAccountID: "<your-aws-account-id>" # e.g. 123456789012
    createBalancers: true
    createConsole: true
    environmentdIAMRoleARN: "<output.materialize_s3_role_arn>" # e.g. arn:aws:iam::123456789012:role/materialize-s3-role
    startupLogFilter: "INFO"

namespace:
  create: true
  name: "materialize"

# Adjust network policies as needed
networkPolicies:
  enabled: true
  egress:
    enabled: true
    cidrs: ["0.0.0.0/0"]
  ingress:
    enabled: true
    cidrs: ["0.0.0.0/0"]
  internal:
    enabled: true

# Uncomment the following block to configure OpenEBS storage
# storage:
#   storageClass:
#     create: true
#     name: "openebs-lvm-instance-store-ext4"
#     provisioner: "local.csi.openebs.io"
#     parameters:
#       storage: "lvm"
#       fsType: "ext4"
#       volgroup: "instance-store-vg"
#     volumeBindingMode: "WaitForFirstConsumer"
```

2. Install the Materialize Operator:
```bash
helm install materialize-operator misc/helm-charts/operator \
  -f materialize-values.yaml
```

3. Verify the installation:
```bash
kubectl get pods -n materialize
```

## Deploy a Materialize Environment

1. Create a secret with the backend configuration (save as `materialize-backend-secret.yaml`):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: materialize-backend
  namespace: materialize-environment
stringData:
  metadata_backend_url: "${terraform_output.metadata_backend_url}"
  persist_backend_url: "${terraform_output.persist_backend_url}"
```

> Replace `${terraform_output.metadata_backend_url}` and `${terraform_output.persist_backend_url}` with the actual values from the Terraform output.

2. Create a Materialize environment (save as `materialize-environment.yaml`):
```yaml
apiVersion: materialize.cloud/v1alpha1
kind: Materialize
metadata:
  name: "${var.service_account_name}"
  namespace: materialize-environment
spec:
  environmentdImageRef: materialize/environmentd:latest
  environmentdResourceRequirements:
    limits:
      memory: 16Gi
    requests:
      cpu: "2"
      memory: 16Gi
  balancerdResourceRequirements:
    limits:
      memory: 256Mi
    requests:
      cpu: "100m"
      memory: 256Mi
  backendSecretName: materialize-backend
```

> Replace `${var.service_account_name}` with the desired name for the Materialize environment. It should be a UUID, eg `12345678-1234-1234-1234-123456789012`.

3. Apply the configuration:
```bash
kubectl create namespace materialize-environment
kubectl apply -f materialize-backend-secret.yaml
kubectl apply -f materialize-environment.yaml
```

4. Monitor the deployment:
```bash
kubectl get materializes -n materialize-environment
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
helm uninstall materialize-operator -n materialize
```

This will remove the operator but preserve any PVs and data. To completely clean up:
```bash
kubectl delete namespace materialize
kubectl delete namespace materialize-environment
```
