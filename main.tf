resource "aws_secretsmanager_secret" "sm" {
  for_each                       = var.secrets
  name                           = try(each.value.name_prefix, null) == null && try(each.value.name, null) == null ? each.key : (try(each.value.name_prefix, null) == null && try(each.value.name, null) != null ? each.value.name : null)
  name_prefix                    = try(each.value.name_prefix, null) != null ? each.value.name_prefix : null
  description                    = try(each.value.description, null)
  kms_key_id                     = try(each.value.kms_key_id, null)
  policy                         = try(each.value.policy, null)
  force_overwrite_replica_secret = try(each.value.force_overwrite_replica_secret, false)
  recovery_window_in_days        = try(each.value.recovery_window_in_days, var.recovery_window_in_days)
  tags                           = merge(var.tags, try(each.value.tags, null))
  dynamic "replica" {
    for_each = try(each.value.replica_regions, {})
    content {
      region     = try(replica.value.region, replica.key)
      kms_key_id = try(replica.value.kms_key_id, null)
    }
  }
}

resource "aws_secretsmanager_secret_version" "sm-sv" {
  for_each       = { for k, v in var.secrets : k => v if !var.unmanaged }
  secret_id      = aws_secretsmanager_secret.sm[each.key].arn
  secret_string  = try(each.value.secret_string, null) != null ? try(each.value.secret_string, null) : (try(each.value.secret_key_value, null) != null ? jsonencode(try(each.value.secret_key_value, {})) : null)
  secret_binary  = try(each.value.secret_binary, null) != null ? base64encode(each.value.secret_binary) : null
  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.sm]
  lifecycle {
    ignore_changes = [
      secret_id,
    ]
  }
}

resource "aws_secretsmanager_secret_version" "sm-svu" {
  for_each       = { for k, v in var.secrets : k => v if var.unmanaged }
  secret_id      = aws_secretsmanager_secret.sm[each.key].arn
  secret_string  = try(each.value.secret_string, null) != null ? each.value.secret_string : (try(each.value.secret_key_value, null) != null ? jsonencode(try(each.value.secret_key_value, {})) : null)
  secret_binary  = try(each.value.secret_binary, null) != null ? base64encode(each.value.secret_binary) : null
  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.sm]

  lifecycle {
    ignore_changes = [
      secret_string,
      secret_binary,
      secret_id,
    ]
  }
}

# Rotate secrets
resource "aws_secretsmanager_secret" "rsm" {
  for_each                       = var.rotate_secrets
  name                           = try(each.value.name_prefix, null) == null && try(each.value.name, null) == null ? each.key : (try(each.value.name_prefix, null) == null && try(each.value.name, null) != null ? each.value.name : null)
  name_prefix                    = try(each.value.name_prefix, null) != null ? each.value.name_prefix : null
  description                    = try(each.value.description, null)
  kms_key_id                     = try(each.value.kms_key_id, null)
  policy                         = try(each.value.policy, null)
  force_overwrite_replica_secret = try(each.value.force_overwrite_replica_secret, false)
  recovery_window_in_days        = try(each.value.recovery_window_in_days, var.recovery_window_in_days)
  tags                           = merge(var.tags, try(each.value.tags, null))
}

resource "aws_secretsmanager_secret_version" "rsm-sv" {
  for_each       = { for k, v in var.rotate_secrets : k => v if !var.unmanaged }
  secret_id      = aws_secretsmanager_secret.rsm[each.key].arn
  secret_string  = try(each.value.secret_string, null) != null ? each.value.secret_string : (try(each.value.secret_key_value, null) != null ? jsonencode(try(each.value.secret_key_value, {})) : null)
  secret_binary  = try(each.value.secret_binary, null) != null ? base64encode(each.value.secret_binary) : null
  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.rsm]
  lifecycle {
    ignore_changes = [
      secret_id,
    ]
  }
}

resource "aws_secretsmanager_secret_version" "rsm-svu" {
  for_each       = { for k, v in var.rotate_secrets : k => v if var.unmanaged }
  secret_id      = aws_secretsmanager_secret.rsm[each.key].arn
  secret_string  = try(each.value.secret_string, null) != null ? each.value.secret_string : (try(each.value.secret_key_value, null) != null ? jsonencode(try(each.value.secret_key_value, {})) : null)
  secret_binary  = try(each.value.secret_binary, null) != null ? base64encode(each.value.secret_binary) : null
  version_stages = var.version_stages
  depends_on     = [aws_secretsmanager_secret.rsm]

  lifecycle {
    ignore_changes = [
      secret_string,
      secret_binary,
      secret_id,
    ]
  }
}

resource "aws_secretsmanager_secret_rotation" "rsm-sr" {
  for_each            = var.rotate_secrets
  secret_id           = aws_secretsmanager_secret.rsm[each.key].arn
  rotation_lambda_arn = each.value.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = try(each.value.automatically_after_days, var.automatically_after_days)
  }
  depends_on = [aws_secretsmanager_secret.rsm]

  lifecycle {
    ignore_changes = [
      secret_id,
    ]
  }
}
