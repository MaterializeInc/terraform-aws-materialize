## Post-Deployment Setup

After successfully deploying the infrastructure with this module, you'll need to:

1. (Optional) Configure storage classes
1. Install the [Materialize Operator](https://github.com/MaterializeInc/materialize/tree/main/misc/helm-charts/operator)
1. Deploy your first Materialize environment

See our [Operator Installation Guide](docs/operator-setup.md) for instructions.

## Connecting to Materialize instances

By default, Network Load Balancers are created for each Materialize instance, with three listeners:
1. Port 6875 for SQL connections to the database.
1. Port 6876 for HTTP(S) connections to the database.
1. Port 8080 for HTTP(S) connections to the web console.

The DNS name and ARN for the NLBs will be in the `terraform output` as `nlb_details`.

#### TLS support

For example purposes, optional TLS support is provided by using `cert-manager` and a self-signed `ClusterIssuer`.

More advanced TLS support using user-provided CAs or per-Materialize `Issuer`s are out of scope of this Terraform module. Please refer to the [cert-manager documentation](https://cert-manager.io/docs/configuration/) for detailed guidance on more advanced usage.

###### To enable installation of `cert-manager` and configuration of the self-signed `ClusterIssuer`
1. Set `install_cert_manager` to `true`.
1. Run `terraform apply`.
1. Set `use_self_signed_cluster_issuer` to `true`.
1. Run `terraform apply`.

Due to limitations in Terraform, it cannot plan Kubernetes resources using CRDs that do not exist yet. We need to first install `cert-manager` in the first `terraform apply`, before defining any `ClusterIssuer` or `Certificate` resources which get created in the second `terraform apply`.

## Upgrade Notes

#### v0.3.0
We now install the AWS Load Balancer Controller and create Network Load Balancers for each Materialize instance.

If managing Materialize instances with this module, additional action may be required to upgrade to this version.

###### If you want to disable NLB support
* Set `install_aws_load_balancer_controller` to `false`.
* Set `materialize_instances[*].create_nlb` to `false`.

###### If you want to enable NLB support
* Leave `install_aws_load_balancer_controller` set to its default of `true`.
* Set `materialize_instances[*].create_nlb` to `false`.
* Run `terraform apply`.
* Set `materialize_instances[*].create_nlb` to `true`.
* Run `terraform apply`.

Due to limitations in Terraform, it cannot plan Kubernetes resources using CRDs that do not exist yet. We need to first install the AWS Load Balancer Controller in the first `terraform apply`, before defining any `TargetGroupBinding` resources which get created in the second `terraform apply`.
