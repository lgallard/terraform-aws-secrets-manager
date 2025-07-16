variable "recovery_window_in_days" {
  description = "Specifies the number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. Example: 7"
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "Recovery window must be 0 (for immediate deletion) or between 7 and 30 days."
  }
}

# Ephemeral mode configuration
variable "ephemeral" {
  description = "Enable ephemeral resources and write-only arguments to prevent sensitive data from being stored in state. Requires Terraform >= 1.11. When enabled, secret values use write-only arguments (_wo) and are not persisted to state. Example: true"
  type        = bool
  default     = false
}

# Secrets with rotation
variable "rotate_secrets" {
  description = "Map of secrets to keep and rotate in AWS Secrets Manager. Each secret must include rotation_lambda_arn. Example: { mysecret = { description = \"My secret\", secret_string = \"secret-value\", rotation_lambda_arn = \"arn:aws:lambda:us-east-1:123456789012:function:my-function\" } }"
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.rotate_secrets :
      try(v.rotation_lambda_arn != null && v.rotation_lambda_arn != "", false)
    ])
    error_message = "All rotate_secrets must have a valid rotation_lambda_arn specified."
  }

  validation {
    condition = alltrue([
      for k, v in var.rotate_secrets : length(regexall("^[a-zA-Z0-9/_+=.@-]+$", k)) > 0
    ])
    error_message = "Rotate secret names must contain only alphanumeric characters, hyphens, underscores, periods, forward slashes, at signs, plus signs, and equal signs."
  }

  validation {
    condition = alltrue([
      for k, v in var.rotate_secrets : length(k) >= 1 && length(k) <= 512
    ])
    error_message = "Rotate secret names must be between 1 and 512 characters long."
  }

  validation {
    condition = alltrue([
      for k, v in var.rotate_secrets :
      try(v.kms_key_id, null) == null || can(regex("^(arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}|alias/[a-zA-Z0-9/_-]+|[a-f0-9-]{36})$", v.kms_key_id))
    ])
    error_message = "KMS key ID must be a valid KMS key ARN, alias, or key ID format."
  }

  validation {
    condition = alltrue([
      for k, v in var.rotate_secrets :
      try(v.automatically_after_days, null) == null || (v.automatically_after_days >= 1 && v.automatically_after_days <= 365)
    ])
    error_message = "automatically_after_days must be between 1 and 365 days."
  }

  validation {
    condition = alltrue([
      for k, v in var.rotate_secrets :
      var.ephemeral == false || (can(v.secret_string_wo_version) && try(v.secret_string_wo_version >= 1, false))
    ])
    error_message = "secret_string_wo_version is required and must be >= 1 when ephemeral is enabled for rotating secrets. Use secret_string_wo_version for all secret types (string, key-value, and binary)."
  }

  validation {
    condition = alltrue([
      for k, v in var.rotate_secrets :
      can(v.secret_string) && can(v.secret_binary) ? false : true
    ])
    error_message = "Cannot specify both secret_string and secret_binary for the same secret."
  }
}

# Regular secrets (non-rotating)
variable "secrets" {
  description = "Map of secrets to keep in AWS Secrets Manager. Example: { mysecret = { description = \"My secret\", secret_string = \"secret-value\" } }"
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.secrets : length(regexall("^[a-zA-Z0-9/_+=.@-]+$", k)) > 0
    ])
    error_message = "Secret names must contain only alphanumeric characters, hyphens, underscores, periods, forward slashes, at signs, plus signs, and equal signs."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : length(k) >= 1 && length(k) <= 512
    ])
    error_message = "Secret names must be between 1 and 512 characters long."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      try(v.kms_key_id, null) == null || can(regex("^(arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}|alias/[a-zA-Z0-9/_-]+|[a-f0-9-]{36})$", v.kms_key_id))
    ])
    error_message = "KMS key ID must be a valid KMS key ARN, alias, or key ID format."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      var.ephemeral == false || (can(v.secret_string_wo_version) && try(v.secret_string_wo_version >= 1, false))
    ])
    error_message = "secret_string_wo_version is required and must be >= 1 when ephemeral is enabled. Use secret_string_wo_version for all secret types (string, key-value, and binary)."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      can(v.secret_string) && can(v.secret_binary) ? false : true
    ])
    error_message = "Cannot specify both secret_string and secret_binary for the same secret."
  }

}

variable "unmanaged" {
  description = "Terraform must ignore secrets lifecycle. Using this option you can initialize the secrets and rotate them outside Terraform, avoiding other users changing or rotating secrets by subsequent Terraform runs. Example: true"
  type        = bool
  default     = false
}

variable "automatically_after_days" {
  description = "Specifies the number of days between automatic scheduled rotations of the secret. Must be between 1 and 365 days. Example: 30"
  type        = number
  default     = 30

  validation {
    condition     = var.automatically_after_days >= 1 && var.automatically_after_days <= 365
    error_message = "Automatically after days must be between 1 and 365."
  }
}

variable "version_stages" {
  description = "List of version stages to be handled. Valid values are 'AWSCURRENT' and 'AWSPENDING'. Kept as null for backwards compatibility. Example: [\"AWSCURRENT\"]"
  type        = list(string)
  default     = null

  validation {
    condition = var.version_stages == null || alltrue([
      for stage in coalesce(var.version_stages, []) : contains(["AWSCURRENT", "AWSPENDING"], stage)
    ])
    error_message = "Version stages must be either 'AWSCURRENT' or 'AWSPENDING'."
  }
}

# Tags
variable "tags" {
  description = "Key-value map of user-defined tags attached to the secret. Keys cannot start with 'aws:'. Example: { Environment = \"prod\", Owner = \"team\" }"
  type        = any
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : !startswith(lower(k), "aws:")
    ])
    error_message = "Tag keys cannot start with 'aws:' (case insensitive)."
  }

  validation {
    condition = alltrue([
      for k, v in var.tags : length(k) >= 1 && length(k) <= 128
    ])
    error_message = "Tag keys must be between 1 and 128 characters long."
  }

  validation {
    condition = alltrue([
      for k, v in var.tags : length(tostring(v)) <= 256
    ])
    error_message = "Tag values must be 256 characters or less."
  }
}
