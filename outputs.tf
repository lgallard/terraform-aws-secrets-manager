output "secret_ids" {
  description = "Secret ids map"
  value       = { for k, v in aws_secretsmanager_secret.sm : k => v["id"] }
}

output "secret_arns" {
  description = "Secrets arns map"
  value       = { for k, v in aws_secretsmanager_secret.sm : k => v["arn"] }
}

# Rotate secrets
output "rotate_secret_ids" {
  description = "Rotate secret ids map"
  value       = { for k, v in aws_secretsmanager_secret.rsm : k => v["id"] }
}

output "rotate_secret_arns" {
  description = "Rotate secret arns map"
  value       = { for k, v in aws_secretsmanager_secret.rsm : k => v["arn"] }
}
