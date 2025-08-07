# TFLint configuration for terraform-aws-secrets-manager

config {
  format = "compact"
  call_module_type = "all"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.42.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Enable additional rules
rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

# Disabled for backward compatibility - existing resource names use kebab-case
rule "terraform_naming_convention" {
  enabled = false
  # format  = "snake_case"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

# AWS-specific rules
rule "aws_secretsmanager_secret_invalid_policy" {
  enabled = true
}

# Note: This rule was removed in newer versions of tflint-ruleset-aws
# rule "aws_secretsmanager_secret_version_secret_string_and_secret_binary" {
#   enabled = true
# }

# Disable specific rules that may not be relevant
rule "terraform_module_pinned_source" {
  enabled = false
}

rule "aws_resource_missing_tags" {
  enabled = false # We allow resources without tags in some cases
}