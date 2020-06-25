variable "default_recovery_window_in_days" {
  description = "A valid JSON document representing a resource policy."
  type        = number
  default     = 30
}

# Secrets
variable "secrets" {
  description = "List of secrets to keep in AWS Secrets Manager"
  type        = any
  default     = []
}

# Tags
variable "tags" {
  description = "Specifies a key-value map of user-defined tags that are attached to the secret."
  type        = any
  default     = {}
}

