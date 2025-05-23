variable "name_prefix" {
  description = "Prefix for all resource names (replaces separate namespace and environment variables)"
  type        = string
}

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
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
