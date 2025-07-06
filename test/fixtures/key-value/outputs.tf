output "secret_arn" {
  description = "ARN of the created key-value secret"
  value       = module.secrets_manager.secret_arns["${var.test_name}-kv-secret"]
}

output "secret_name" {
  description = "Name of the created key-value secret"
  value       = "${var.test_name}-kv-secret"
}

output "secret_id" {
  description = "ID of the created key-value secret"
  value       = module.secrets_manager.secret_ids["${var.test_name}-kv-secret"]
}