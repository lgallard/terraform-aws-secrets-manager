locals {
  # Cache lookups for regular secrets to improve performance and readability
  secrets_config = {
    for k, v in var.secrets : k => {
      name_prefix                    = lookup(v, "name_prefix", null)
      name                           = lookup(v, "name", null)
      description                    = lookup(v, "description", null)
      kms_key_id                     = lookup(v, "kms_key_id", null)
      policy                         = lookup(v, "policy", null)
      force_overwrite_replica_secret = lookup(v, "force_overwrite_replica_secret", false)
      recovery_window_in_days        = lookup(v, "recovery_window_in_days", var.recovery_window_in_days)
      tags                           = lookup(v, "tags", null)
      replica_regions                = lookup(v, "replica_regions", {})
      secret_string                  = lookup(v, "secret_string", null)
      secret_key_value               = lookup(v, "secret_key_value", null)
      secret_binary                  = lookup(v, "secret_binary", null)
      secret_string_wo_version       = lookup(v, "secret_string_wo_version", null)
      # Computed name based on priority: name > name_prefix > key
      computed_name        = lookup(v, "name", null) != null ? lookup(v, "name", null) : (lookup(v, "name_prefix", null) != null ? null : k)
      computed_name_prefix = lookup(v, "name_prefix", null)
    }
  }

  # Cache lookups for rotating secrets
  rotate_secrets_config = {
    for k, v in var.rotate_secrets : k => {
      name_prefix                    = lookup(v, "name_prefix", null)
      name                           = lookup(v, "name", null)
      description                    = lookup(v, "description", null)
      kms_key_id                     = lookup(v, "kms_key_id", null)
      policy                         = lookup(v, "policy", null)
      force_overwrite_replica_secret = lookup(v, "force_overwrite_replica_secret", false)
      recovery_window_in_days        = lookup(v, "recovery_window_in_days", var.recovery_window_in_days)
      tags                           = lookup(v, "tags", null)
      replica_regions                = lookup(v, "replica_regions", {})
      secret_string                  = lookup(v, "secret_string", null)
      secret_key_value               = lookup(v, "secret_key_value", null)
      secret_binary                  = lookup(v, "secret_binary", null)
      secret_string_wo_version       = lookup(v, "secret_string_wo_version", null)
      rotation_lambda_arn            = lookup(v, "rotation_lambda_arn", null)
      automatically_after_days       = lookup(v, "automatically_after_days", var.automatically_after_days)
      # Computed name based on priority: name > name_prefix > key
      computed_name        = lookup(v, "name", null) != null ? lookup(v, "name", null) : (lookup(v, "name_prefix", null) != null ? null : k)
      computed_name_prefix = lookup(v, "name_prefix", null)
    }
  }

  # Helper function to compute secret values based on ephemeral mode - reduces code duplication
  compute_secret_values = {
    for config_name, config_map in {
      "secrets"        = local.secrets_config,
      "rotate_secrets" = local.rotate_secrets_config
      } : config_name => {
      for k, v in config_map : k => {
        # Regular parameters (when ephemeral is disabled)
        secret_string = !var.ephemeral ? (
          v.secret_string != null ? v.secret_string :
          (v.secret_key_value != null ? jsonencode(v.secret_key_value) : null)
        ) : null
        secret_binary = !var.ephemeral ? (
          v.secret_binary != null ? base64encode(v.secret_binary) : null
        ) : null

        # Write-only parameters (when ephemeral is enabled)
        secret_string_wo = var.ephemeral ? (
          v.secret_string != null ? v.secret_string :
          (v.secret_key_value != null ? jsonencode(v.secret_key_value) :
          (v.secret_binary != null ? base64encode(v.secret_binary) : null))
        ) : null

        secret_string_wo_version = var.ephemeral ? v.secret_string_wo_version : null
      }
    }
  }
}

resource "aws_secretsmanager_secret" "sm" {
  for_each                       = var.secrets
  name                           = local.secrets_config[each.key].computed_name
  name_prefix                    = local.secrets_config[each.key].computed_name_prefix
  description                    = local.secrets_config[each.key].description
  kms_key_id                     = local.secrets_config[each.key].kms_key_id
  policy                         = local.secrets_config[each.key].policy
  force_overwrite_replica_secret = local.secrets_config[each.key].force_overwrite_replica_secret
  recovery_window_in_days        = local.secrets_config[each.key].recovery_window_in_days
  tags                           = merge(var.default_tags, var.tags, local.secrets_config[each.key].tags)

  dynamic "replica" {
    for_each = local.secrets_config[each.key].replica_regions
    content {
      region     = try(replica.value.region, replica.key)
      kms_key_id = try(replica.value.kms_key_id, null)
    }
  }
}

resource "aws_secretsmanager_secret_version" "sm-sv" {
  for_each  = { for k, v in var.secrets : k => v if !var.unmanaged }
  secret_id = aws_secretsmanager_secret.sm[each.key].arn

  # Use computed values from locals to eliminate code duplication
  secret_string            = local.compute_secret_values["secrets"][each.key].secret_string
  secret_binary            = local.compute_secret_values["secrets"][each.key].secret_binary
  secret_string_wo         = local.compute_secret_values["secrets"][each.key].secret_string_wo
  secret_string_wo_version = local.compute_secret_values["secrets"][each.key].secret_string_wo_version

  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.sm]
  lifecycle {
    ignore_changes = [
      secret_id,
    ]
  }
}

resource "aws_secretsmanager_secret_version" "sm-svu" {
  for_each  = { for k, v in var.secrets : k => v if var.unmanaged }
  secret_id = aws_secretsmanager_secret.sm[each.key].arn

  # Use computed values from locals to eliminate code duplication
  secret_string            = local.compute_secret_values["secrets"][each.key].secret_string
  secret_binary            = local.compute_secret_values["secrets"][each.key].secret_binary
  secret_string_wo         = local.compute_secret_values["secrets"][each.key].secret_string_wo
  secret_string_wo_version = local.compute_secret_values["secrets"][each.key].secret_string_wo_version

  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.sm]

  lifecycle {
    ignore_changes = [
      secret_string,
      secret_binary,
      secret_string_wo,
      secret_string_wo_version,
      secret_id,
    ]
  }
}

# Rotate secrets
resource "aws_secretsmanager_secret" "rsm" {
  for_each                       = var.rotate_secrets
  name                           = local.rotate_secrets_config[each.key].computed_name
  name_prefix                    = local.rotate_secrets_config[each.key].computed_name_prefix
  description                    = local.rotate_secrets_config[each.key].description
  kms_key_id                     = local.rotate_secrets_config[each.key].kms_key_id
  policy                         = local.rotate_secrets_config[each.key].policy
  force_overwrite_replica_secret = local.rotate_secrets_config[each.key].force_overwrite_replica_secret
  recovery_window_in_days        = local.rotate_secrets_config[each.key].recovery_window_in_days
  tags                           = merge(var.default_tags, var.tags, local.rotate_secrets_config[each.key].tags)
}

resource "aws_secretsmanager_secret_version" "rsm-sv" {
  for_each  = { for k, v in var.rotate_secrets : k => v if !var.unmanaged }
  secret_id = aws_secretsmanager_secret.rsm[each.key].arn

  # Use computed values from locals to eliminate code duplication
  secret_string            = local.compute_secret_values["rotate_secrets"][each.key].secret_string
  secret_binary            = local.compute_secret_values["rotate_secrets"][each.key].secret_binary
  secret_string_wo         = local.compute_secret_values["rotate_secrets"][each.key].secret_string_wo
  secret_string_wo_version = local.compute_secret_values["rotate_secrets"][each.key].secret_string_wo_version

  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.rsm]
  lifecycle {
    ignore_changes = [
      secret_id,
    ]
  }
}

resource "aws_secretsmanager_secret_version" "rsm-svu" {
  for_each  = { for k, v in var.rotate_secrets : k => v if var.unmanaged }
  secret_id = aws_secretsmanager_secret.rsm[each.key].arn

  # Use computed values from locals to eliminate code duplication
  secret_string            = local.compute_secret_values["rotate_secrets"][each.key].secret_string
  secret_binary            = local.compute_secret_values["rotate_secrets"][each.key].secret_binary
  secret_string_wo         = local.compute_secret_values["rotate_secrets"][each.key].secret_string_wo
  secret_string_wo_version = local.compute_secret_values["rotate_secrets"][each.key].secret_string_wo_version

  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.rsm]

  lifecycle {
    ignore_changes = [
      secret_string,
      secret_binary,
      secret_string_wo,
      secret_string_wo_version,
      secret_id,
    ]
  }
}

resource "aws_secretsmanager_secret_rotation" "rsm-sr" {
  for_each            = var.rotate_secrets
  secret_id           = aws_secretsmanager_secret.rsm[each.key].arn
  rotation_lambda_arn = local.rotate_secrets_config[each.key].rotation_lambda_arn

  rotation_rules {
    automatically_after_days = local.rotate_secrets_config[each.key].automatically_after_days
  }
  depends_on = [aws_secretsmanager_secret.rsm]

  lifecycle {
    ignore_changes = [
      secret_id,
    ]
  }
}
