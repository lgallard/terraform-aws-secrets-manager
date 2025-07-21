# Ephemeral Secrets Example

This example demonstrates how to use the ephemeral feature to prevent sensitive data from being stored in Terraform state.

## Overview

When `ephemeral = true` is set, the module uses write-only arguments (`_wo` parameters) that prevent sensitive values from being persisted in the Terraform state file. This feature requires Terraform 1.11 or later.

## Key Features

- **Security**: Sensitive values are not stored in Terraform state
- **Compatibility**: Works with all secret types (plaintext, key-value, binary)
- **Versioning**: Uses version parameters to control updates
- **Backward Compatibility**: Default behavior remains unchanged

## Usage

To use ephemeral secrets, set `ephemeral = true` in your module configuration:

```hcl
module "secrets_manager" {
  source = "../../"
  
  ephemeral = true
  
  secrets = {
    db_password = {
      description = "Database password (ephemeral)"
      secret_string = var.db_password
      secret_string_wo_version = 1
    }
  }
}
```

## Version Control

When using ephemeral secrets, you can control when secrets are updated by incrementing the version parameter:

- `secret_string_wo_version` - for string secrets and binary secrets (binary secrets are stored as base64-encoded strings when ephemeral is enabled)

## Requirements

- Terraform >= 1.11
- AWS Provider >= 2.67.0

## Benefits

1. **Enhanced Security**: Sensitive data never appears in state files
2. **Compliance**: Meets security requirements for sensitive data handling
3. **Audit Trail**: Version parameters provide update tracking
4. **Flexibility**: Can be used with ephemeral resources for end-to-end security

## Example with Ephemeral Resources

```hcl
# Generate ephemeral password
ephemeral "random_password" "db_password" {
  length = 16
  special = true
}

# Use ephemeral password in secret
module "secrets_manager" {
  source = "../../"
  
  ephemeral = true
  
  secrets = {
    db_password = {
      description = "Database password (ephemeral)"
      secret_string = ephemeral.random_password.db_password.result
      secret_string_wo_version = 1
    }
  }
}
```

This configuration ensures that the password remains ephemeral throughout the entire workflow without being exposed in Terraform's plan or state files.

## Migration from Regular to Ephemeral Secrets

⚠️ **Important**: Migrating from regular to ephemeral secrets will recreate the secret resources.

### Migration Steps

1. **Update Configuration**: Add `ephemeral = true` and `secret_string_wo_version = 1` to each secret
2. **Plan Changes**: Run `terraform plan` to review the changes (resources will be recreated)
3. **Apply Changes**: Run `terraform apply` to migrate to ephemeral mode
4. **Verify**: Check that sensitive values are no longer in the state file

### Before Migration
```hcl
module "secrets" {
  source = "../../"
  
  secrets = {
    db_password = {
      description = "Database password"
      secret_string = var.db_password
    }
  }
}
```

### After Migration
```hcl
module "secrets" {
  source = "../../"
  
  ephemeral = true
  
  secrets = {
    db_password = {
      description = "Database password (ephemeral)"
      secret_string = var.db_password
      secret_string_wo_version = 1
    }
  }
}
```

See `migration.tf` for a complete migration example.

## Common Issues and Solutions

### Issue: Version Parameter Missing
**Error**: `secret_string_wo_version is required and must be >= 1 when ephemeral is enabled`
**Solution**: Add `secret_string_wo_version = 1` to your secret configuration

### Issue: Invalid Version Value
**Error**: Version parameter validation fails
**Solution**: Ensure `secret_string_wo_version` is a positive integer (>= 1)

### Issue: Conflicting Version Parameters
**Error**: Cannot specify both version parameters
**Solution**: Use only `secret_string_wo_version` for all secret types (including binary)

## Advanced Patterns

### GitHub Issue #80: For_each with Ephemeral Passwords

See `ephemeral-for-each-example.tf` for the **working solution** to use ephemeral `random_password` resources with `for_each` patterns.

**Problem**: Module variables cannot accept ephemeral values with `for_each` due to Terraform limitations.

**Solution**: Use direct AWS resources instead of the module wrapper:

```hcl
ephemeral "random_password" "db_passwords" {
  for_each = var.db_users
  length   = 24
  special  = true
}

resource "aws_secretsmanager_secret_version" "db_secret_versions" {
  for_each = var.db_users
  secret_id = aws_secretsmanager_secret.db_secrets[each.key].id
  
  secret_string_wo = jsonencode({
    password = ephemeral.random_password.db_passwords[each.key].result
    username = each.key
    # ... other fields
  })
  
  secret_string_wo_version = 1
}
```

This approach provides the same security benefits while working within Terraform's architectural constraints.

## Files in this Directory

- `main.tf` - Basic ephemeral secrets using the module
- `ephemeral-for-each-example.tf` - Working solution for ephemeral + for_each patterns
- `migration.tf` - Example migration from regular to ephemeral secrets
- `validation-test.tf` - Test configuration for validation
- `ephemeral-for-each-patterns.md` - Detailed technical analysis and solutions
- `ephemeral-limitations.md` - Explanation of Terraform limitations