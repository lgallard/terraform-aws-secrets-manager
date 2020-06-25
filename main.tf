resource "aws_secretsmanager_secret" "sm" {
  count                   = length(local.secrets)
  name                    = lookup(element(local.secrets, count.index), "name")
  name_prefix             = lookup(element(local.secrets, count.index), "name_prefix")
  description             = lookup(element(local.secrets, count.index), "description")
  kms_key_id              = lookup(element(local.secrets, count.index), "kms_key_id")
  policy                  = lookup(element(local.secrets, count.index), "policy")
  recovery_window_in_days = lookup(element(local.secrets, count.index), "recovery_window_in_days")

  # Tags
  tags = merge(var.tags, lookup(element(local.secrets, count.index), "tags"))


}

resource "aws_secretsmanager_secret_version" "sm-sv" {
  count         = length(local.secrets)
  secret_id     = aws_secretsmanager_secret.sm.*.id[count.index]
  secret_string = lookup(element(local.secrets, count.index), "secret_string")
  secret_binary = lookup(element(local.secrets, count.index), "secret_binary") != null ? base64encode(lookup(element(local.secrets, count.index), "secret_binary")) : null
  depends_on    = [aws_secretsmanager_secret.sm]
}


locals {

  secrets = [
    for secret in var.secrets : {
      name                    = lookup(secret, "name", null)
      name_prefix             = lookup(secret, "name_prefix", null)
      description             = lookup(secret, "description", null)
      kms_key_id              = lookup(secret, "kms_key_id", null)
      policy                  = lookup(secret, "policy", null)
      recovery_window_in_days = lookup(secret, "recovery_window_in_days", var.default_recovery_window_in_days)
      secret_string           = lookup(secret, "secret_string", null) != null ? lookup(secret, "secret_string") : (lookup(secret, "secret_key_values", null) != null ? jsonencode(lookup(secret, "secret_key_values", {})) : null)
      secret_binary           = lookup(secret, "secret_string", null) == null ? lookup(secret, "secret_binary", null) : null
      #secret_key_values       = jsonencode(lookup(secret, "secret_key_values", {}))
      tags = lookup(secret, "tags", {})
    }
  ]


}
