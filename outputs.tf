output "secret_ids" {
  description = "Map of secret names to their resource IDs. Use these IDs to reference secrets in other Terraform resources."
  value       = { for k, v in aws_secretsmanager_secret.sm : k => v["id"] }
}

output "secret_arns" {
  description = "Map of secret names to their ARNs. Use these ARNs to grant permissions or reference secrets in IAM policies and other AWS resources."
  value       = { for k, v in aws_secretsmanager_secret.sm : k => v["arn"] }
}

# Rotate secrets
output "rotate_secret_ids" {
  description = "Map of rotating secret names to their resource IDs. Use these IDs to reference rotating secrets in other Terraform resources."
  value       = { for k, v in aws_secretsmanager_secret.rsm : k => v["id"] }
}

output "rotate_secret_arns" {
  description = "Map of rotating secret names to their ARNs. Use these ARNs to grant permissions or reference rotating secrets in IAM policies and other AWS resources."
  value       = { for k, v in aws_secretsmanager_secret.rsm : k => v["arn"] }
}
