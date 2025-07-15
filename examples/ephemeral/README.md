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

- `secret_string_wo_version` - for string secrets
- `secret_binary_wo_version` - for binary secrets

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