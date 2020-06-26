output "secret_ids" {
  description = "Secret id list"
  value       = aws_secretsmanager_secret.sm.*.id
}

output "secret_arns" {
  description = "Secret arn list"
  value       = aws_secretsmanager_secret.sm.*.arn
}

# Rotate secrets
output "rotate_secret_ids" {
  description = "Secret id list"
  value       = aws_secretsmanager_secret.rsm.*.id
}

output "rotate_secret_arns" {
  description = "Secret arn list"
  value       = aws_secretsmanager_secret.rsm.*.arn
}
