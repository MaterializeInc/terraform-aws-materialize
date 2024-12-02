# Configuring TLS for the Materialize Operator

After [installing the Materialize Operator](./operator-setup.md), follow these steps to configure TLS for secure communication.

## Prerequisites

- Materialize Operator installed on your cluster
- cert-manager v1.13.0+ installed
- `kubectl` configured to interact with your cluster

## Install cert-manager

If cert-manager is not already installed on your cluster, you can install it using the following command:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.0/cert-manager.yaml
```

Verify the installation:

```bash
kubectl get pods -n cert-manager
```

## Configure Certificate Issuers

Before configuring TLS for Materialize, you'll need to set up appropriate certificate issuers in your cluster. The specific configuration will depend on your environment and requirements. Please refer to the [cert-manager documentation](https://cert-manager.io/docs/configuration/) for detailed guidance on:

- Choosing the right issuer type for your environment
- Configuring production-ready certificate issuers
- Setting up intermediate CAs if required
- Managing certificate lifecycle and renewal

Once you have configured your certificate issuers, you can proceed with the Materialize TLS configuration.

## Configure Materialize with TLS

1. Update your Materialize Operator Helm values to include TLS configuration or create a new values file (save as `materialize-values-tls.yaml`):

```yaml
# Existing values...

# Add TLS configuration
tls:
  defaultCertificateSpecs:
    balancerdExternal:
      duration: 2160h  # 90 days
      renewBefore: 360h  # 15 days
      privateKey:
        algorithm: ECDSA
        size: 256
    consoleExternal:
      duration: 2160h  # 90 days
      renewBefore: 360h  # 15 days
      privateKey:
        algorithm: ECDSA
        size: 256
```

> Note: Configure only the fields that should be common across all Materialize environments. DNS names and secret templates should be configured per environment in the Materialize Custom Resource.

2. Update the Materialize Operator installation:

```bash
helm upgrade materialize-operator misc/helm-charts/operator \
  -f materialize-values-tls.yaml
```

3. Create or update your Materialize environment (save as `materialize-environment-tls.yaml`):

```yaml
apiVersion: materialize.cloud/v1alpha1
kind: Materialize
metadata:
  name: 12345678-1234-1234-1234-123456789012
  namespace: materialize-environment
spec:
  environmentdImageRef: materialize/environmentd:v0.126.0  # Use your desired version
  backendSecretName: materialize-backend
  requestRollout: 22222222-2222-2222-2222-222222222222
  forceRollout: 33333333-3333-3333-3333-333333333333
  balancerdExternalCertificateSpec:
    dnsNames:
      - mz-balancerd-prod.example.com
      - mz-balancerd-prod-internal.example.com
  consoleExternalCertificateSpec:
    dnsNames:
      - mz-console-prod.example.com
      - mz-console-prod-internal.example.com
```

The `forceRollout` and `requestRollout` fields are used to trigger a rollout of the Materialize environment. They should be set to unique UUIDs.

4. Apply the environment configuration:

```bash
kubectl apply -f materialize-environment-tls.yaml
```

## Verify TLS Configuration

1. Check certificate status:

```bash
kubectl get certificates -n materialize-environment
kubectl get certificaterequests -n materialize-environment
```

You should see certificates being issued and ready:

```
# Certificates:
NAME                                 READY   SECRET                                AGE
ca-key-pair                          True    ca-key-pair                           4m21s
mztjut43kipm-balancerd-external      True    mztjut43kipm-balancerd-external-tls   43s
mztjut43kipm-console-external        True    mztjut43kipm-console-external-tls     3m15s
mztjut43kipm-environmentd-external   True    mztjut43kipm-environmentd-tls         43s

# Certificate requests:
NAME                                   APPROVED   DENIED   READY   ISSUER            REQUESTOR                                         AGE
ca-key-pair-1                          True                True    dns01             system:serviceaccount:cert-manager:cert-manager   4m30s
mztjut43kipm-balancerd-external-1      True                True    dns01             system:serviceaccount:cert-manager:cert-manager   52s
mztjut43kipm-console-external-1        True                True    dns01             system:serviceaccount:cert-manager:cert-manager   3m24s
mztjut43kipm-environmentd-external-1   True                True    intermediate-ca   system:serviceaccount:cert-manager:cert-manager   52s
```

2. Verify the Materialize environment is running:

```bash
kubectl get materializes -n materialize-environment
kubectl get pods -n materialize-environment
```

## Troubleshooting

If certificates are not being issued:

1. Check cert-manager logs:

```bash
kubectl logs -n cert-manager -l app=cert-manager
```

2. Check certificate events:

```bash
kubectl describe certificate -n materialize-environment
```

3. Check issuer status:

```bash
kubectl describe clusterissuer dns01
kubectl describe issuer intermediate-ca -n materialize-environment
```

If a certificate is stuck in a pending state:

```bash
# Delete the failing certificate request
kubectl delete certificaterequest <request-name> -n materialize-environment

# Delete and recreate the issuer if needed
kubectl delete issuer intermediate-ca -n materialize-environment
kubectl apply -f certificate-issuers.yaml
```
