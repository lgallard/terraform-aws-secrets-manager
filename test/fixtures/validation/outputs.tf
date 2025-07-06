output "secret_arn" {
  description = "ARN of the created validation secret"
  value       = module.secrets_manager.secret_arns["${var.test_name}-validation-secret"]
}

output "secret_name" {
  description = "Name of the created validation secret"
  value       = "${var.test_name}-validation-secret"
}