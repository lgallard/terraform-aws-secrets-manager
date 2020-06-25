output "secret_ids" {
  description = "Secret id list"
  value       = aws_secretsmanager_secret.sm.*.id
}

output "secret_arns" {
  description = "Secret arn list"
  value       = aws_secretsmanager_secret.sm.*.arn
}
output "secret_rotation_enabled" {
  description = "Secret rotation_enabled list"
  value       = aws_secretsmanager_secret.sm.*.rotation_enabled
}
