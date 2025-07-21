# GitHub Issue #80: Working User Pattern with Ephemeral Passwords
#
# This example demonstrates the WORKING solution for the user's original request:
# https://github.com/lgallard/terraform-aws-secrets-manager/issues/80
#
# The user wanted to use ephemeral random_password resources with for_each patterns.
# While the exact module pattern doesn't work due to Terraform limitations, 
# this direct AWS resources approach provides the same functionality and security.

# Variables matching the user's original setup
variable "db_users" {
  description = "Database users configuration"
  type = map(object({
    role = string
  }))
  default = {
    "admin" = { role = "admin" }
    "app"   = { role = "application" }
    "readonly" = { role = "readonly" }
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "myapp"
}

# User's desired ephemeral random passwords - THIS WORKS!
ephemeral "random_password" "db_passwords" {
  for_each         = var.db_users
  length           = 24
  special          = true
  override_special = "!@#%^&*-_=<>?"
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  min_lower        = 1
}

# KMS key for encryption (recommended for production)
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for ${var.app_name} secrets"
  deletion_window_in_days = 7
  
  tags = {
    Name        = "${var.app_name}-secrets-key"
    Purpose     = "secrets-encryption"
    Environment = "production"
  }
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/${var.app_name}-secrets"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# WORKING SOLUTION: Direct AWS resources with ephemeral passwords
# This provides the exact functionality the user wanted
resource "aws_secretsmanager_secret" "db_secrets" {
  for_each = var.db_users

  name                    = "db/${var.app_name}/${each.key}"
  description             = "${var.app_name} database credentials for ${each.key} user"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0  # Set to 7-30 for production

  tags = {
    Environment = "production"
    Application = var.app_name
    User        = each.key
    Role        = each.value.role
    Purpose     = "database-credentials"
  }
}

# Create secret versions with ephemeral random passwords
# The ephemeral passwords are never stored in Terraform state
resource "aws_secretsmanager_secret_version" "db_secret_versions" {
  for_each = var.db_users

  secret_id = aws_secretsmanager_secret.db_secrets[each.key].id
  
  # Using write-only parameter with ephemeral random password
  # This ensures sensitive data is never stored in Terraform state
  secret_string_wo = jsonencode({
    username = each.key
    password = ephemeral.random_password.db_passwords[each.key].result
    host     = "db.${var.app_name}.internal"
    port     = 5432
    engine   = "postgres"
    dbname   = var.app_name
    role     = each.value.role
  })
  
  # Version control for ephemeral updates
  secret_string_wo_version = 1
}

# Optional: Add rotation (requires Lambda function)
# Uncomment if you have a rotation Lambda function set up
/*
resource "aws_secretsmanager_secret_rotation" "db_rotations" {
  for_each = var.db_users

  secret_id           = aws_secretsmanager_secret.db_secrets[each.key].id
  rotation_lambda_arn = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:rotate-db-secret"

  rotation_rules {
    automatically_after_days = 90
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
*/

# Outputs for validation and integration
output "secret_arns" {
  description = "ARNs of created secrets"
  value = {
    for k, secret in aws_secretsmanager_secret.db_secrets :
    k => secret.arn
  }
}

output "secret_names" {
  description = "Names of created secrets"
  value = {
    for k, secret in aws_secretsmanager_secret.db_secrets :
    k => secret.name
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = aws_kms_key.secrets_key.arn
}

output "summary" {
  description = "Summary of the deployed resources"
  value = {
    app_name      = var.app_name
    users_count   = length(var.db_users)
    users         = keys(var.db_users)
    pattern_used  = "direct-aws-resources-with-ephemeral"
    security_note = "Ephemeral passwords are not stored in Terraform state"
  }
}