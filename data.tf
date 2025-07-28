# Data sources for existing secrets
# These can be used to reference secrets that exist outside of this module

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