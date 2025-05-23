variable "install_openebs" {
  description = "Whether to install OpenEBS for NVMe storage"
  type        = bool
  default     = true
}

variable "openebs_namespace" {
  description = "Namespace for OpenEBS components"
  type        = string
  default     = "openebs"
}

variable "openebs_version" {
  description = "Version of OpenEBS Helm chart to install"
  type        = string
  default     = "4.2.0"
}
