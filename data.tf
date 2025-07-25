# Data sources for existing secrets
# These can be used to reference secrets that exist outside of this module

variable "existing_secrets" {
  description = "Map of existing secret names or ARNs to import as data sources. Useful for referencing secrets created outside this module. Example: { existing_secret = \"arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret\" }"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.existing_secrets : 
      can(regex("^(arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:[a-zA-Z0-9/_+=.@-]+|[a-zA-Z0-9/_+=.@-]+)$", v))
    ])
    error_message = "Existing secret values must be valid secret names or ARNs."
  }
}

data "aws_secretsmanager_secret" "existing" {
  for_each = var.existing_secrets
  
  # Handle both ARN and name formats
  arn  = can(regex("^arn:", each.value)) ? each.value : null
  name = can(regex("^arn:", each.value)) ? null : each.value
}

data "aws_secretsmanager_secret_version" "existing" {
  for_each  = var.existing_secrets
  secret_id = data.aws_secretsmanager_secret.existing[each.key].arn
}