output "secret_arn" {
  description = "ARN of the created binary secret"
  value       = module.secrets_manager.secret_arns["${var.test_name}-binary-secret"]
}

output "secret_name" {
  description = "Name of the created binary secret"
  value       = "${var.test_name}-binary-secret"
}

output "secret_id" {
  description = "ID of the created binary secret"
  value       = module.secrets_manager.secret_ids["${var.test_name}-binary-secret"]
}