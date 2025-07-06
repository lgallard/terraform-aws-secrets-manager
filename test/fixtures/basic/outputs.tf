output "secret_arns" {
  description = "ARNs of the created secrets"
  value       = values(module.secrets_manager.secret_arns)
}

output "secret_names" {
  description = "Names of the created secrets"
  value       = keys(module.secrets_manager.secret_arns)
}

output "secret_ids" {
  description = "IDs of the created secrets"
  value       = values(module.secrets_manager.secret_ids)
}