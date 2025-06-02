variable "openebs_namespace" {
  description = "Namespace for OpenEBS components"
  type        = string
  default     = "openebs"
}

variable "create_openebs_namespace" {
  description = "Whether to create the OpenEBS namespace. Set to false if the namespace already exists."
  type        = bool
  default     = true
}

variable "openebs_version" {
  description = "Version of OpenEBS Helm chart to install"
  type        = string
  default     = "4.2.0"
}
