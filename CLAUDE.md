# Terraform AWS Secrets Manager Module - Development Guidelines

## Overview
This document outlines Terraform-specific development guidelines for the terraform-aws-secrets-manager module, focusing on best practices for AWS infrastructure as code.

## Module Structure & Organization

### File Organization
- **main.tf** - Primary resource definitions and locals
- **variables.tf** - Input variable definitions with validation
- **outputs.tf** - Output value definitions  
- **versions.tf** - Provider version constraints
- **iam.tf** - IAM roles and policies (for secret access)
- **notifications.tf** - SNS and notification configurations
- **rotation.tf** - Secret rotation configurations
- **replica.tf** - Cross-region replication configurations
- **policy.tf** - Resource-based policy configurations

### Code Organization Principles
- Group related resources logically in separate files
- Use descriptive locals for complex expressions
- Maintain backward compatibility with existing variable names
- Keep validation logic close to variable definitions

## Terraform Best Practices

### Resource Creation Patterns
**Favor `for_each` over `count`** for resource creation:

```hcl
# Preferred: Using for_each
resource "aws_secretsmanager_secret" "this" {
  for_each = var.enabled ? var.secrets : {}
  
  name = each.value.name
  # ...
}

# Avoid: Using count when for_each is more appropriate
resource "aws_secretsmanager_secret" "this" {
  count = var.enabled ? length(var.secrets) : 0
  # ...
}
```

### Variables & Validation
Use validation blocks for critical inputs where appropriate:

```hcl
# Example: Basic validation for naming conventions
variable "secret_name" {
  description = "Name of the secret to create"
  type        = string
  default     = null

  validation {
    condition     = var.secret_name == null ? true : can(regex("^[0-9A-Za-z-_/.]{1,512}$", var.secret_name))
    error_message = "The secret_name must be between 1 and 512 characters, contain only alphanumeric characters, hyphens, underscores, periods, and forward slashes."
  }
}
```

### Locals Organization
Structure locals for clarity and reusability:

```hcl
locals {
  # Resource creation conditions
  should_create_secret = var.enabled && var.secret_name != null
  should_create_replica = local.should_create_secret && length(var.replica_regions) > 0
  
  # Data processing
  secrets = concat(local.secret, var.secrets)
  
  # Validation helpers
  rotation_requirements_met = var.rotation_enabled && var.rotation_lambda_arn != null
}
```

## Testing Requirements

### Test Coverage for New Features
**Write tests when adding new features:**
- Create corresponding test files in `test/` directory
- Add example configurations in `examples/` directory
- Use Terratest for integration testing
- Test both success and failure scenarios

### Test Coverage for Modifications
**Add tests when modifying functionalities (if missing):**
- Review existing test coverage before making changes
- Add missing tests for functionality being modified
- Ensure backward compatibility is tested
- Test edge cases and error conditions

### Testing Strategy
- Use Terratest for integration testing
- Include examples for common use cases
- Test resource creation and destruction
- Validate outputs and state consistency
- Test different input combinations

## Security Considerations

### General Security Practices
- Consider encryption requirements (KMS keys, etc.)
- Follow principle of least privilege for IAM
- Implement proper access controls
- Use secure defaults where possible

### Example Security Patterns
```hcl
# Example: KMS key validation (optional)
variable "secret_kms_key_arn" {
  description = "The server-side encryption key for secrets"
  type        = string
  default     = null

  validation {
    condition     = var.secret_kms_key_arn == null ? true : can(regex("^arn:aws:kms:", var.secret_kms_key_arn))
    error_message = "The secret_kms_key_arn must be a valid KMS key ARN."
  }
}
```

## Module Development Guidelines

### Backward Compatibility
- Maintain existing variable interfaces when possible
- Use deprecation warnings for old patterns
- Provide migration guidance for breaking changes
- Document version-specific changes

### Code Quality
- Run `terraform fmt` before committing
- Use `terraform validate` to check syntax
- Consider pre-commit hooks for automated checks
- Use consistent naming conventions

## Specific Module Patterns

### Multi-Secret Support
Handle different input formats gracefully:

```hcl
# Support both legacy and new secret formats
secret_configurations = flatten([
  var.secret_configurations,
  [for secret in try(tolist(var.secrets), []) : try(secret.config, [])],
  [for k, secret in try(tomap(var.secrets), {}) : try(secret.config, [])],
  [for secret in var.secret_definitions : try(secret.config, [])],
  [for group in var.secret_groups : flatten([for secret in try(group.secrets, []) : try(secret.config, [])])]
])
```

### Using for_each for Complex Resources
```hcl
# Example: Creating multiple secret replicas
resource "aws_secretsmanager_secret_replica" "this" {
  for_each = {
    for idx, replica in var.secret_replicas : 
    "${replica.region}_${idx}" => replica
  }
  
  secret_id = aws_secretsmanager_secret.this[each.value.secret_name].id
  region    = each.value.region
  
  dynamic "kms_key_id" {
    for_each = each.value.kms_key_id != null ? [1] : []
    content {
      kms_key_id = each.value.kms_key_id
    }
  }
}
```

## Development Workflow

### Pre-commit Requirements
- Run `terraform fmt` on modified files
- Execute `terraform validate`
- Run tests for affected functionality
- Consider running security scanning tools
- Update documentation for variable changes

### Release Management
- **DO NOT manually update CHANGELOG.md** - we use release-please for automated changelog generation
- Use conventional commit messages for proper release automation
- Follow semantic versioning principles in commit messages

### Documentation Standards
- Document all variables with clear descriptions
- Include examples for complex variable structures
- Update README.md for new features
- Let release-please handle version history

## Common Patterns to Consider

1. **Prefer for_each** - Use `for_each` over `count` for better resource management
2. **Test Coverage** - Write tests for new features and missing test coverage
3. **Flexible Inputs** - Support multiple input formats where reasonable
4. **Validation Balance** - Add validation where it prevents common errors
5. **Consistent Naming** - Follow established naming conventions
6. **Resource Management** - Handle resource creation conflicts gracefully
7. **Backward Compatibility** - Maintain compatibility when possible
8. **Security Defaults** - Use secure defaults where appropriate

## Provider Version Management

```hcl
# Example provider configuration
terraform {
  required_version = ">= v0.14.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
```

*Note: Version constraints should be chosen based on actual requirements and compatibility needs.*