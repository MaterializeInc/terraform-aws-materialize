# General Variables
variable "namespace" {
  description = "Namespace for all resources, usually the organization or project name"
  type        = string
  validation {
    condition     = length(var.namespace) <= 12 && can(regex("^[a-z][a-z0-9-]+$", var.namespace))
    error_message = "Namespace must be lowercase alphanumeric and hyphens only, start with a letter, max 12 characters"
  }
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  validation {
    condition     = length(var.environment) <= 8 && can(regex("^[a-z0-9]+$", var.environment))
    error_message = "Environment must be lowercase alphanumeric only, max 8 characters"
  }
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "materialize"
  }
}

# Networking Variables
variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "network_id" {
  default     = ""
  description = "The ID of the VPC in which resources will be deployed. Only used if create_vpc is false."
  type        = string
}

variable "network_private_subnet_ids" {
  default     = []
  description = "A list of private subnet IDs in the VPC. Only used if create_vpc is false."
  type        = list(string)
}

variable "network_public_subnet_ids" {
  default     = []
  description = "A list of public subnet IDs in the VPC. Only used if create_vpc is false."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

# EKS Variables
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_group_instance_types" {
  description = <<EOF
Instance types for worker nodes.

Recommended Configuration for Running Materialize with disk:
- Tested instance types: `r6gd`, `r7gd` families (ARM-based Graviton instances)
- Enable disk setup when using `r7gd`
- Note: Ensure instance store volumes are available and attached to the nodes for optimal performance with disk-based workloads.
EOF
  type        = list(string)
  default     = ["r7gd.2xlarge"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for worker nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_group_ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
}

variable "cluster_enabled_log_types" {
  description = "List of desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_cluster_creator_admin_permissions" {
  description = "To add the current caller identity as an administrator"
  type        = bool
  default     = true
}

# RDS Variables
variable "postgres_version" {
  description = "Version of PostgreSQL to use"
  type        = string
  default     = "15"
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.large"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling (in GB)"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "materialize"
}

variable "database_username" {
  description = "Username for the database"
  type        = string
  default     = "materialize"
}

variable "database_password" {
  description = "Password for the database (should be provided via tfvars or environment variable)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.database_password) >= 8 && can(regex("^[[:print:]]+$", var.database_password)) && !can(regex("[/@\" ]", var.database_password))
    error_message = "Database password must be at least 8 characters, contain only printable ASCII characters, excluding '/', '@', '\"' (double quotes), and ' ' (space)."
  }
}

variable "db_multi_az" {
  description = "Enable multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# S3 Variables
variable "bucket_force_destroy" {
  description = "Enable force destroy for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_bucket_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_bucket_encryption" {
  description = "Enable server-side encryption for the S3 bucket"
  type        = bool
  default     = true
}

variable "bucket_lifecycle_rules" {
  description = "List of lifecycle rules for the S3 bucket"
  type = list(object({
    id                                 = string
    enabled                            = bool
    prefix                             = string
    transition_days                    = number
    transition_storage_class           = string
    noncurrent_version_expiration_days = number
  }))
  default = [{
    id                                 = "cleanup"
    enabled                            = true
    prefix                             = ""
    transition_days                    = 90
    transition_storage_class           = "STANDARD_IA"
    noncurrent_version_expiration_days = 90
  }]
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "metrics_retention_days" {
  description = "Number of days to retain CloudWatch metrics"
  type        = number
  default     = 7
}

variable "kubernetes_namespace" {
  description = "The Kubernetes namespace for the Materialize resources"
  type        = string
  default     = "materialize-environment"
}

variable "service_account_name" {
  description = "Name of the service account"
  type        = string
  default     = "12345678-1234-1234-1234-123456789012"
}

variable "log_group_name_prefix" {
  description = "Prefix for the CloudWatch log group name (will be combined with environment name)"
  type        = string
  default     = "materialize"
}

variable "install_aws_load_balancer_controller" {
  description = "Whether to install the AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "install_cert_manager" {
  description = "Whether to install cert-manager."
  type        = bool
  default     = false
}

variable "use_self_signed_cluster_issuer" {
  description = "Whether to install and use a self-signed ClusterIssuer for TLS. Due to limitations in Terraform, this may not be enabled before the cert-manager CRDs are installed."
  type        = bool
  default     = false
}

variable "cert_manager_namespace" {
  description = "The name of the namespace in which cert-manager is or will be installed."
  type        = string
  default     = "cert-manager"
}

# Materialize Helm Chart Variables
variable "install_materialize_operator" {
  description = "Whether to install the Materialize operator"
  type        = bool
  default     = true
}

variable "helm_chart" {
  description = "Chart name from repository or local path to chart. For local charts, set the path to the chart directory."
  type        = string
  default     = "materialize-operator"
}

variable "use_local_chart" {
  description = "Whether to use a local chart instead of one from a repository"
  type        = bool
  default     = false
}

variable "operator_version" {
  description = "Version of the Materialize operator to install"
  type        = string
  default     = null
}

variable "operator_namespace" {
  description = "Namespace for the Materialize operator"
  type        = string
  default     = "materialize"
}

variable "orchestratord_version" {
  description = "Version of the Materialize orchestrator to install"
  type        = string
  default     = "v0.130.4"
}

variable "helm_values" {
  description = "Additional Helm values to merge with defaults"
  type        = any
  default     = {}
}

variable "materialize_instances" {
  description = "Configuration for Materialize instances. Due to limitations in Terraform, `materialize_instances` cannot be defined on the first `terraform apply`."
  type = list(object({
    name                             = string
    namespace                        = optional(string)
    database_name                    = string
    environmentd_version             = optional(string, "v0.130.4")
    cpu_request                      = optional(string, "1")
    memory_request                   = optional(string, "1Gi")
    memory_limit                     = optional(string, "1Gi")
    create_database                  = optional(bool, true)
    create_nlb                       = optional(bool, true)
    internal_nlb                     = optional(bool, true)
    enable_cross_zone_load_balancing = optional(bool, true)
    in_place_rollout                 = optional(bool, false)
    request_rollout                  = optional(string)
    force_rollout                    = optional(string)
    balancer_memory_request          = optional(string, "256Mi")
    balancer_memory_limit            = optional(string, "256Mi")
    balancer_cpu_request             = optional(string, "100m")
  }))
  default = []

  validation {
    condition = alltrue([
      for instance in var.materialize_instances :
      instance.request_rollout == null ||
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", instance.request_rollout))
    ])
    error_message = "Request rollout must be a valid UUID in the format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }

  validation {
    condition = alltrue([
      for instance in var.materialize_instances :
      instance.force_rollout == null ||
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", instance.force_rollout))
    ])
    error_message = "Force rollout must be a valid UUID in the format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}

variable "install_metrics_server" {
  description = "Whether to install the metrics-server for the Materialize Console"
  type        = bool
  default     = true
}

variable "enable_disk_support" {
  description = "Enable disk support for Materialize using OpenEBS and NVMe instance storage. When enabled, this configures OpenEBS, runs the disk setup script for NVMe devices, and creates appropriate storage classes."
  type        = bool
  default     = true
}

variable "disk_support_config" {
  description = "Advanced configuration for disk support (only used when enable_disk_support = true)"
  type = object({
    install_openebs           = optional(bool, true)
    run_disk_setup_script     = optional(bool, true)
    create_storage_class      = optional(bool, true)
    openebs_version           = optional(string, "4.2.0")
    openebs_namespace         = optional(string, "openebs")
    storage_class_name        = optional(string, "openebs-lvm-instance-store-ext4")
    storage_class_provisioner = optional(string, "local.csi.openebs.io")
    storage_class_parameters = optional(object({
      storage  = optional(string, "lvm")
      fsType   = optional(string, "ext4")
      volgroup = optional(string, "instance-store-vg")
    }), {})
  })
  default = {}
}
