# Ephemeral Resources with terraform-aws-secrets-manager

## TL;DR: Current Limitation

❌ **The user's desired pattern is NOT directly supported due to Terraform core limitations:**

```hcl
# THIS PATTERN DOES NOT WORK:
ephemeral "random_password" "db_passwords" {
  for_each = var.db_users  # Creates ephemeral passwords
}

module "db_users_secrets_manager" {
  ephemeral = true
  rotate_secrets = {
    for username, role in var.db_users : "db-${var.name}-${username}" => {
      password = ephemeral.random_password.db_passwords[username].result  # ❌ Cannot pass ephemeral to module
    }
  }
}
```

✅ **Working alternatives are provided below.**

## Root Cause Analysis

### Issue 1: Module Variables Cannot Accept Ephemeral Values (BY DESIGN)
- Terraform variables that accept ephemeral values must be declared with `ephemeral = true`
- However, when a variable has `ephemeral = true`, the ENTIRE variable becomes ephemeral
- Ephemeral variables cannot be used with `for_each` (Terraform needs persistent resource keys)

### Issue 2: Architectural Limitation
```hcl
variable "rotate_secrets" {
  ephemeral = true  # This makes the ENTIRE map ephemeral
}

resource "aws_secretsmanager_secret" "rsm" {
  for_each = var.rotate_secrets  # ❌ FAILS: Cannot use ephemeral value in for_each
}
```

**This is a fundamental Terraform limitation, not a bug in our module.**

## Working Solutions

### Solution 1: Direct Resource Usage (RECOMMENDED)

Create secrets directly without the module wrapper:

```hcl
# Variables
variable "db_users" {
  type = map(object({
    role = string
  }))
}

variable "app_name" {
  type = string
}

# Ephemeral passwords
ephemeral "random_password" "db_passwords" {
  for_each         = var.db_users
  length           = 24
  special          = true
  override_special = "!@#%^&*-_=<>?"
  min_numeric      = 1
}

# KMS key
resource "aws_kms_key" "secrets_key" {
  description = "KMS key for secrets"
}

# Create secrets directly (THIS WORKS!)
resource "aws_secretsmanager_secret" "db_secrets" {
  for_each = var.db_users

  name                    = "db-${var.app_name}-${each.key}"
  description             = "${var.app_name} database credentials for ${each.key}"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0

  tags = {
    Environment = "production"
    User        = each.key
  }
}

# Create secret versions with ephemeral values (THIS WORKS!)
resource "aws_secretsmanager_secret_version" "db_secret_versions" {
  for_each = var.db_users

  secret_id = aws_secretsmanager_secret.db_secrets[each.key].id
  
  # Using write-only parameter with ephemeral value
  secret_string_wo = jsonencode({
    username = each.key
    password = ephemeral.random_password.db_passwords[each.key].result
    host     = "db.${var.app_name}.internal"
    port     = 5432
    engine   = "postgres"
    dbname   = var.app_name
  })
  
  secret_string_wo_version = 1
}

# Add rotation
resource "aws_secretsmanager_secret_rotation" "db_rotations" {
  for_each = var.db_users

  secret_id           = aws_secretsmanager_secret.db_secrets[each.key].id
  rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate-secret"

  rotation_rules {
    automatically_after_days = 90
  }
}
```

### Solution 2: Individual Module Instances

For smaller numbers of secrets, create separate module calls:

```hcl
# Ephemeral passwords
ephemeral "random_password" "db_passwords" {
  for_each = var.db_users
  length   = 24
  special  = true
}

# Individual module for admin user
module "db_admin_secret" {
  source = "lgallard/secrets-manager/aws"
  
  ephemeral = true

  rotate_secrets = {
    "db-${var.app_name}-admin" = {
      description = "Database admin credentials"
      secret_key_value = {
        username = "admin"
        password = ephemeral.random_password.db_passwords["admin"].result
        host     = "db.${var.app_name}.internal"
        port     = 5432
      }
      secret_string_wo_version  = 1
      rotation_lambda_arn       = var.rotation_lambda_arn
      automatically_after_days  = 90
    }
  }
}

# Individual module for app user  
module "db_app_secret" {
  source = "lgallard/secrets-manager/aws"
  
  ephemeral = true

  rotate_secrets = {
    "db-${var.app_name}-app" = {
      description = "Database app credentials"
      secret_key_value = {
        username = "app"
        password = ephemeral.random_password.db_passwords["app"].result
        host     = "db.${var.app_name}.internal"
        port     = 5432
      }
      secret_string_wo_version  = 1
      rotation_lambda_arn       = var.rotation_lambda_arn
      automatically_after_days  = 90
    }
  }
}
```

### Solution 3: Module with Pre-defined Keys

Create a specialized version where secret names are not dynamic:

```hcl
module "ephemeral_db_secrets" {
  source = "lgallard/secrets-manager/aws"
  
  ephemeral = true

  rotate_secrets = {
    "db-admin" = {
      description = "Database admin credentials"
      secret_key_value = {
        username = "admin"
        password = ephemeral.random_password.db_passwords["admin"].result
      }
      secret_string_wo_version = 1
    }
    "db-app" = {
      description = "Database app credentials"  
      secret_key_value = {
        username = "app"
        password = ephemeral.random_password.db_passwords["app"].result
      }
      secret_string_wo_version = 1
    }
  }
}
```

## Key Points

1. ✅ **Our module DOES support ephemeral mode** - The `ephemeral = true` parameter works correctly
2. ✅ **Write-only parameters work** - `secret_string_wo_version` prevents state storage  
3. ❌ **Dynamic for_each with ephemeral values is impossible** - This is a Terraform core limitation
4. ✅ **Direct resource usage is the best workaround** - Gives full control and flexibility
5. ✅ **Individual module instances work** - Good for small, known sets of secrets

## Migration Path

If you're currently using the pattern that doesn't work:

1. **For dynamic secrets**: Use **Solution 1** (direct resources)
2. **For small, known sets**: Use **Solution 2** (individual modules)  
3. **For static configurations**: Use **Solution 3** (pre-defined keys)

## Version Requirements

- **Terraform**: >= 1.11.0 (for ephemeral resources and write-only arguments)
- **AWS Provider**: >= 2.67.0
- **Module**: >= 0.16.0 (when released with ephemeral fixes)

## State Security

All solutions properly prevent sensitive data from being stored in Terraform state by using:
- `secret_string_wo` (write-only parameter)  
- `secret_string_wo_version` (version control for ephemeral updates)
- `ephemeral = true` (module-level ephemeral mode)