# Backward compatible outputs (maintained for existing users)
output "secret_ids" {
  description = "Map of secret names to their resource IDs. Use these IDs to reference secrets in other Terraform resources."
  value       = { for k, v in aws_secretsmanager_secret.sm : k => v["id"] }
}

output "secret_arns" {
  description = "Map of secret names to their ARNs. Use these ARNs to grant permissions or reference secrets in IAM policies and other AWS resources."
  value       = { for k, v in aws_secretsmanager_secret.sm : k => v["arn"] }
}

output "rotate_secret_ids" {
  description = "Map of rotating secret names to their resource IDs. Use these IDs to reference rotating secrets in other Terraform resources."
  value       = { for k, v in aws_secretsmanager_secret.rsm : k => v["id"] }
}

output "rotate_secret_arns" {
  description = "Map of rotating secret names to their ARNs. Use these ARNs to grant permissions or reference rotating secrets in IAM policies and other AWS resources."
  value       = { for k, v in aws_secretsmanager_secret.rsm : k => v["arn"] }
}

# Enhanced comprehensive outputs
output "secrets" {
  description = "Complete map of regular secrets with all attributes including ARNs, names, KMS keys, descriptions, and replica information."
  value = { for k, v in aws_secretsmanager_secret.sm : k => {
    arn                     = v.arn
    id                      = v.id
    name                    = v.name
    description             = v.description
    kms_key_id              = v.kms_key_id
    policy                  = v.policy
    recovery_window_in_days = v.recovery_window_in_days
    tags                    = v.tags
    tags_all                = v.tags_all
    replica                 = v.replica
  } }
}

output "rotate_secrets" {
  description = "Complete map of rotating secrets with all attributes including ARNs, names, KMS keys, descriptions, and rotation information."
  value = { for k, v in aws_secretsmanager_secret.rsm : k => {
    arn                     = v.arn
    id                      = v.id
    name                    = v.name
    description             = v.description
    kms_key_id              = v.kms_key_id
    policy                  = v.policy
    recovery_window_in_days = v.recovery_window_in_days
    tags                    = v.tags
    tags_all                = v.tags_all
  } }
}

# Secret version outputs (conditional based on management mode)
output "secret_versions" {
  description = "Map of managed secret versions with their ARNs and version information."
  value = var.unmanaged ? {} : { for k, v in aws_secretsmanager_secret_version.sm-sv : k => {
    arn            = v.arn
    id             = v.id
    secret_id      = v.secret_id
    version_id     = v.version_id
    version_stages = v.version_stages
  } }
}

output "rotate_secret_versions" {
  description = "Map of managed rotating secret versions with their ARNs and version information."
  value = var.unmanaged ? {} : { for k, v in aws_secretsmanager_secret_version.rsm-sv : k => {
    arn            = v.arn
    id             = v.id
    secret_id      = v.secret_id
    version_id     = v.version_id
    version_stages = v.version_stages
  } }
}

# Rotation configuration outputs
output "secret_rotations" {
  description = "Map of secret rotation configurations with Lambda ARN and rotation schedule information."
  value = { for k, v in aws_secretsmanager_secret_rotation.rsm-sr : k => {
    arn                 = v.arn
    id                  = v.id
    secret_id           = v.secret_id
    rotation_enabled    = v.rotation_enabled
    rotation_lambda_arn = v.rotation_lambda_arn
    rotation_rules      = v.rotation_rules
  } }
}

# Summary outputs for easy reference
output "all_secret_arns" {
  description = "List of all secret ARNs (both regular and rotating) for easy reference in IAM policies."
  value = concat(
    [for v in aws_secretsmanager_secret.sm : v.arn],
    [for v in aws_secretsmanager_secret.rsm : v.arn]
  )
}

output "secrets_by_name" {
  description = "Map of actual secret names to their ARNs, useful for referencing secrets by their AWS names rather than Terraform keys."
  value = merge(
    { for k, v in aws_secretsmanager_secret.sm : v.name => v.arn },
    { for k, v in aws_secretsmanager_secret.rsm : v.name => v.arn }
  )
}

# Data source outputs for existing secrets
output "existing_secrets" {
  description = "Map of existing secrets referenced as data sources with their complete attributes."
  value = length(var.existing_secrets) > 0 ? { for k, v in data.aws_secretsmanager_secret.existing : k => {
    arn                     = v.arn
    id                      = v.id
    name                    = v.name
    description             = v.description
    kms_key_id              = v.kms_key_id
    policy                  = v.policy
    recovery_window_in_days = v.recovery_window_in_days
    tags                    = v.tags
    replica                 = v.replica
  } } : {}
}

output "existing_secret_versions" {
  description = "Map of existing secret versions with their current values and metadata."
  value = length(var.existing_secrets) > 0 ? { for k, v in data.aws_secretsmanager_secret_version.existing : k => {
    arn            = v.arn
    id             = v.id
    secret_id      = v.secret_id
    version_id     = v.version_id
    version_stages = v.version_stages
    # Note: secret_string and secret_binary are sensitive and not exposed
  } } : {}
}
