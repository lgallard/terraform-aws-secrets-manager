resource "aws_secretsmanager_secret" "sm" {
  for_each                       = var.secrets
  name                           = lookup(each.value, "name_prefix", null) == null && lookup(each.value, "name", null) == null ? each.key : (lookup(each.value, "name_prefix", null) == null && lookup(each.value, "name", null) != null ? each.value.name : null)
  name_prefix                    = lookup(each.value, "name_prefix", null) != null ? lookup(each.value, "name_prefix") : null
  description                    = lookup(each.value, "description", null)
  kms_key_id                     = lookup(each.value, "kms_key_id", null)
  policy                         = lookup(each.value, "policy", null)
  force_overwrite_replica_secret = lookup(each.value, "force_overwrite_replica_secret", false)
  recovery_window_in_days        = lookup(each.value, "recovery_window_in_days", var.recovery_window_in_days)
  tags                           = merge(var.tags, lookup(each.value, "tags", null))
  dynamic "replica" {
    for_each = lookup(each.value, "replica_regions", {})
    content {
      region     = try(replica.value.region, replica.key)
      kms_key_id = try(replica.value.kms_key_id, null)
    }
  }
}

resource "aws_secretsmanager_secret_version" "sm-sv" {
  for_each       = { for k, v in var.secrets : k => v if !var.unmanaged }
  secret_id      = aws_secretsmanager_secret.sm[each.key].arn
  secret_string  = lookup(each.value, "secret_string", null) != null ? lookup(each.value, "secret_string", null) : (lookup(each.value, "secret_key_value", null) != null ? jsonencode(lookup(each.value, "secret_key_value", {})) : null)
  secret_binary  = lookup(each.value, "secret_binary", null) != null ? base64encode(lookup(each.value, "secret_binary")) : null
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
  secret_string  = lookup(each.value, "secret_string", null) != null ? lookup(each.value, "secret_string") : (lookup(each.value, "secret_key_value", null) != null ? jsonencode(lookup(each.value, "secret_key_value", {})) : null)
  secret_binary  = lookup(each.value, "secret_binary", null) != null ? base64encode(lookup(each.value, "secret_binary")) : null
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
  name                           = lookup(each.value, "name_prefix", null) == null && lookup(each.value, "name", null) == null ? each.key : (lookup(each.value, "name_prefix", null) == null && lookup(each.value, "name", null) != null ? each.value.name : null)
  name_prefix                    = lookup(each.value, "name_prefix", null) != null ? lookup(each.value, "name_prefix") : null
  description                    = lookup(each.value, "description")
  kms_key_id                     = lookup(each.value, "kms_key_id", null)
  policy                         = lookup(each.value, "policy", null)
  force_overwrite_replica_secret = lookup(each.value, "force_overwrite_replica_secret", false)
  recovery_window_in_days        = lookup(each.value, "recovery_window_in_days", var.recovery_window_in_days)
  tags                           = merge(var.tags, lookup(each.value, "tags", null))
}

resource "aws_secretsmanager_secret_version" "rsm-sv" {
  for_each       = { for k, v in var.rotate_secrets : k => v if !var.unmanaged }
  secret_id      = aws_secretsmanager_secret.rsm[each.key].arn
  secret_string  = lookup(each.value, "secret_string", null) != null ? lookup(each.value, "secret_string") : (lookup(each.value, "secret_key_value", null) != null ? jsonencode(lookup(each.value, "secret_key_value", {})) : null)
  secret_binary  = lookup(each.value, "secret_binary", null) != null ? base64encode(lookup(each.value, "secret_binary")) : null
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
  secret_string  = lookup(each.value, "secret_string", null) != null ? lookup(each.value, "secret_string") : (lookup(each.value, "secret_key_value", null) != null ? jsonencode(lookup(each.value, "secret_key_value", {})) : null)
  secret_binary  = lookup(each.value, "secret_binary", null) != null ? base64encode(lookup(each.value, "secret_binary")) : null
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
  rotation_lambda_arn = lookup(each.value, "rotation_lambda_arn")

  rotation_rules {
    automatically_after_days = lookup(each.value, "automatically_after_days", var.automatically_after_days)
  }
  depends_on = [aws_secretsmanager_secret.rsm]

  lifecycle {
    ignore_changes = [
      secret_id,
    ]
  }
}

resource "random_password" "password" {
  length           = var.length_password
  special          = var.special_characters
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
