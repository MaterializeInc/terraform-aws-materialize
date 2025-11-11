variable "swap_enabled" {
  description = "Enable swap for Materialize. When enabled, this configures swap on a new nodepool, and adds it to the clusterd node selectors."
  type        = bool
  default     = false
}
