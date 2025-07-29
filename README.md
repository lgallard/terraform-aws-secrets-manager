![Terraform](https://lgallardo.com/images/terraform.jpg)
# terraform-aws-secrets-manager

Terraform module to create [Amazon Secrets Manager](https://aws.amazon.com/secrets-manager/) resources with comprehensive input validation and advanced features.

AWS Secrets Manager helps you protect secrets needed to access your applications, services, and IT resources. The service enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle.

## Features

- ✅ **Input Validation**: Comprehensive validation for all variables to prevent configuration errors
- ✅ **Type Safety**: Strongly typed variables with structured object definitions
- ✅ **Secret Rotation**: Built-in support for automatic secret rotation with Lambda functions
- ✅ **Cross-Region Replication**: Support for replicating secrets across AWS regions
- ✅ **KMS Encryption**: Support for customer-managed KMS keys
- ✅ **Resource Policies**: Attach custom IAM policies to secrets
- ✅ **Flexible Secret Types**: Support for plain text, key/value pairs, and binary secrets

## Examples

Check the [examples](/examples/) folder where you can see the complete compilation of snippets.

## Basic Usage

### Plain text secrets

```hcl
module "secrets-manager-1" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    secret-1 = {
      description             = "My secret 1"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
    },
    secret-2 = {
      description             = "My secret 2"
      recovery_window_in_days = 7
      secret_string           = "This is another example"
    }
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }
}
```

### Key/Value secrets

```hcl
module "secrets-manager-2" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    secret-kv-1 = {
      description = "This is a key/value secret"
      secret_key_value = {
        key1 = "value1"
        key2 = "value2"
      }
      recovery_window_in_days = 7
    },
    secret-kv-2 = {
      description = "Another key/value secret"
      secret_key_value = {
        username = "user"
        password = "topsecret"
      }
      tags = {
        app = "web"
      }
      recovery_window_in_days = 7
    },
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }
}
```

### Binary secrets

```hcl
module "secrets-manager-3" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    secret-binary-1 = {
      description   = "This is a binary secret"
      secret_binary = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDt4TcI58h4G0wR+GcDY+0VJR10JNvG92jEKGaKxeMaOkfsXflVGsYXbfVBBCG/n3uHtTse7baYLB6LWQAuYWL1SHJVhhTQ7pPiocFWibAvJlVo1l7qJEDu2OxKpWEleCE+p3ufNXAy7v5UFO7EOnj0Zg6R3F/MiAWbQnaEHcYzNtogyC24YBecBLrBXZNi1g0AN1hM9k+3XvWUYTf9vPv8LIWnqo7y4Q2iEGWWurf37YFl1LzX4mG/Co+Vfe5TlZSe2YPMYWlw0ZKaKvwzInRR6dPMAflo3ABzlduiIbSdp110uGqB8i2M8eGXNDxR7Ni4nnLWnT9r1cpWhXWP6pAG4Xg8+x7+PIg/pgjgJNmsURw+jPD6+hkCw2Vz16EIgkC2b7lj0V6J4LncUoRzU/1sAzCQ4tspy3SKBUinYoxbDvXleF66FHEjfparnvNwfslBx0IJjG2uRwuX6zrsNIsGF1stEjz+eyAOtFV4/wRjRcCNDZvl1ODzIvwf8pAWddE= lgallard@server1"
      recovery_window_in_days = 7
    },
    secret-binary-2 = {
      name                    = "secret-binary-2"
      description             = "Another binary secret"
      secret_binary           = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzc818NSC6oJYnNjVWoF43+IuQpqc3WyS8BWZ50uawK5lY/aObweX2YiXPv2CoVvHUM0vG7U7BDBvNi2xwsT9n9uT27lcVQsTa8iDtpyoeBhcj3vJ60Jd04UfoMP7Og6UbD+KGiaqQ0LEtMXq6d3i619t7V0UkaJ4MXh2xl5y3bV4zNzTXdSScJnvMFfjLW0pJOOqltLma3NQ9ILVdMSK2Vzxc87T+h/jp0VuUAX4Rx9DqmxEU/4JadXmow/BKy69KVwAk/AQ8jL7OwD2YAxlMKqKnOsBJQF27YjmMD240UjkmnPlxkV8+g9b2hA0iM5GL+5MWg6pPUE0BYdarCmwyuaWYhv/426LnfHTz9UVC3y9Hg5c4X4I6AdJJUmarZXqxnMe9jJiqiQ+CAuxW3m0gIGsEbUul6raG73xFuozlaXq3J+kMCVW24eG2i5fezgmtiysIf/dpcUo+YLkX+U8jdMQg9IwCY0bf8XL39kwJ7u8uWU8+7nMcS9VQ5llVVMk= lgallard@server2"
      recovery_window_in_days = 7
      tags = {
        app = "web"
      }
    }
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }
}
```

## Advanced Usage

### Secrets with KMS Encryption

```hcl
module "secrets-manager-kms" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    database-credentials = {
      description = "Database credentials encrypted with customer KMS key"
      secret_key_value = {
        username = "admin"
        password = "super-secret-password"
        host     = "db.example.com"
        port     = "5432"
      }
      kms_key_id              = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      recovery_window_in_days = 7
    }
  }

  tags = {
    Environment = "production"
    KMSEncrypted = "true"
  }
}
```

### Secrets with Resource Policies

```hcl
data "aws_iam_policy_document" "secret_policy" {
  statement {
    sid    = "AllowApplicationAccess"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::123456789012:role/MyApplicationRole"]
    }
    
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

module "secrets-manager-policy" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    app-config = {
      description   = "Application configuration with resource policy"
      secret_string = jsonencode({
        api_key = "secret-api-key"
        config  = "production-config"
      })
      policy                  = data.aws_iam_policy_document.secret_policy.json
      recovery_window_in_days = 14
    }
  }
}
```

### Cross-Region Secret Replication

```hcl
module "secrets-manager-replication" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    global-config = {
      description   = "Global configuration replicated across regions"
      secret_string = "global-configuration-data"
      
      replica_regions = {
        "us-west-2" = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
        "eu-west-1" = "arn:aws:kms:eu-west-1:123456789012:key/87654321-4321-4321-4321-210987654321"
      }
      
      force_overwrite_replica_secret = true
      recovery_window_in_days        = 7
    }
  }

  tags = {
    ReplicationEnabled = "true"
    GlobalResource     = "true"
  }
}
```

### Lifecycle Configuration

If you need to configure lifecycle rules for your secrets (such as `prevent_destroy`, `create_before_destroy`, or `ignore_changes`), you must configure them on individual resources since lifecycle blocks cannot be used with module calls.

Here are the recommended approaches:

#### Option 1: Create secrets directly with lifecycle rules

```hcl
# Create secret directly with lifecycle protection
resource "aws_secretsmanager_secret" "critical_secret" {
  name        = "critical-database-password"
  description = "Critical database password - protected from accidental deletion"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = "production"
    Critical    = "true"
  }
}

resource "aws_secretsmanager_secret_version" "critical_secret_version" {
  secret_id     = aws_secretsmanager_secret.critical_secret.id
  secret_string = "super-secret-password"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
```

#### Option 2: Use module alongside protected resources

```hcl
# Use module for convenience, then protect specific secrets separately
module "secrets-manager" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    app-config = {
      description   = "Application configuration"
      secret_string = "app-configuration-data"
    }
  }
}

# Create additional protected secret with lifecycle rules
resource "aws_secretsmanager_secret" "protected_secret" {
  name        = "critical-database-password"
  description = "Critical database password - protected from accidental deletion"

  lifecycle {
    prevent_destroy       = true
    create_before_destroy = true
  }

  tags = {
    Environment = "production"
    Critical    = "true"
  }
}

resource "aws_secretsmanager_secret_version" "protected_version" {
  secret_id     = aws_secretsmanager_secret.protected_secret.id
  secret_string = "super-secret-password"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
```

This approach follows Terraform's requirement that lifecycle blocks only contain literal values and can only be used on resource blocks, not module calls.

## Secrets Rotation

If you need to rotate your secrets, use `rotate_secrets` map to define them. The lambda function must exist and have the right permissions to rotate secrets in AWS Secrets Manager:

```hcl
module "secrets-manager-rotation" {
  source = "lgallard/secrets-manager/aws"

  rotate_secrets = {
    database-password = {
      description             = "Database password rotated every 30 days"
      secret_string           = "initial-password"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123456789012:function:rotate-secret"
      automatically_after_days = 30
      recovery_window_in_days = 15
    },
    api-key = {
      description             = "API key rotated weekly"
      secret_string           = "initial-api-key"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123456789012:function:rotate-secret"
      automatically_after_days = 7
      recovery_window_in_days = 7
    }
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }
}

# Lambda function for rotation (example)
# AWS templates available at https://github.com/aws-samples/aws-secrets-manager-rotation-lambdas
module "rotate_secret_lambda" {
  source  = "spring-media/lambda/aws"
  version = "5.2.0"

  filename         = "secrets_manager_rotation.zip"
  function_name    = "rotate-secret"
  handler          = "secrets_manager_rotation.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/secrets_manager_rotation.zip")

  environment = {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.us-east-1.amazonaws.com"
    }
  }
}

resource "aws_lambda_permission" "allow_secret_manager_call_lambda" {
  function_name = module.rotate_secret_lambda.function_name
  statement_id  = "AllowExecutionSecretManager"
  action        = "lambda:InvokeFunction"
  principal     = "secretsmanager.amazonaws.com"
}
```

## Mixed Secret Definitions

You can define different types of secrets (string, key/value, or binary) in the same `secrets` or `rotate_secrets` map:

```hcl
module "secrets-manager-mixed" {
  source = "lgallard/secrets-manager/aws"

  secrets = {
    plain-text-secret = {
      description             = "A plain text secret"
      recovery_window_in_days = 7
      secret_string           = "This is a plain text secret"
    }
    
    key-value-secret = {
      description = "A key/value secret for database credentials"
      secret_key_value = {
        username = "dbuser"
        password = "dbpassword"
        host     = "database.example.com"
        port     = "5432"
        database = "myapp"
      }
      recovery_window_in_days = 14
      tags = {
        Type = "database"
      }
    }
    
    binary-secret = {
      description   = "SSH private key"
      secret_binary = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC..."
      recovery_window_in_days = 30
      tags = {
        Type = "ssh-key"
      }
    }
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }
}
```

## Input Validation Reference

This module includes comprehensive input validation to prevent configuration errors:

### Secret Names
- Must contain only alphanumeric characters, hyphens, underscores, periods, forward slashes, at signs, plus signs, and equal signs
- Must be between 1 and 512 characters long
- Examples: `my-secret`, `app/config`, `db_credentials`

### Recovery Window
- Must be 0 (immediate deletion) or between 7-30 days
- Default: 30 days

### Rotation Frequency  
- Must be between 1-365 days for `automatically_after_days`
- Default: 30 days

### Version Stages
- Only `AWSCURRENT` and `AWSPENDING` are valid
- Example: `["AWSCURRENT"]`

### KMS Key IDs
- Must be valid KMS key ARN, alias, or key ID format
- Examples:
  - ARN: `arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012`
  - Alias: `alias/my-key`
  - Key ID: `12345678-1234-1234-1234-123456789012`

### Tags
- Keys cannot start with `aws:` (case insensitive)
- Keys must be 1-128 characters long
- Values must be 256 characters or less

## Troubleshooting

### Common Issues and Solutions

#### Invalid Secret Name Error
```
Error: Secret names must contain only alphanumeric characters, hyphens, underscores, periods, forward slashes, at signs, plus signs, and equal signs.
```
**Solution**: Check your secret names for invalid characters. Only use: `a-z`, `A-Z`, `0-9`, `-`, `_`, `.`, `/`, `@`, `+`, `=`

#### Recovery Window Validation Error
```
Error: Recovery window must be 0 (for immediate deletion) or between 7 and 30 days.
```
**Solution**: Set `recovery_window_in_days` to either `0` or a value between `7` and `30`.

#### KMS Key Format Error
```
Error: KMS key ID must be a valid KMS key ARN, alias, or key ID format.
```
**Solution**: Ensure your KMS key follows one of these formats:
- `arn:aws:kms:region:account:key/key-id`
- `alias/key-alias`
- `key-id` (UUID format)

#### Rotation Lambda Missing Error
```
Error: All rotate_secrets must have a valid rotation_lambda_arn specified.
```
**Solution**: When using `rotate_secrets`, always provide a valid `rotation_lambda_arn`. The Lambda function must exist and have proper permissions.

#### Tag Validation Error
```
Error: Tag keys cannot start with 'aws:' (case insensitive).
```
**Solution**: Remove any tags that start with `aws:`, `AWS:`, or any case variation.

### Performance Considerations

1. **Large Numbers of Secrets**: If you have many secrets, consider splitting them across multiple module instances to improve Terraform performance.

2. **Cross-Region Replication**: Be aware that replication increases costs and may impact performance. Only replicate secrets that truly need global availability.

3. **Rotation Frequency**: More frequent rotations increase Lambda costs and API calls. Balance security requirements with operational costs.

### Security Best Practices

1. **Least Privilege Access**: Use resource policies to grant minimal required permissions.

2. **Encryption**: Always use KMS encryption for sensitive secrets, preferably with customer-managed keys.

3. **Monitoring**: Enable CloudTrail logging for Secrets Manager API calls to monitor access patterns.

4. **Rotation**: Implement regular rotation for database credentials and API keys.

5. **Version Management**: Use version stages appropriately and avoid storing multiple active versions unnecessarily.

## Version 0.5.0+ breaking changes
Issue [#13](https://github.com/lgallard/terraform-aws-secrets-manager/issues/13) highlighted the fact that changing the secrets order will recreate the secrets (for example, adding a new secret in the top of the list o removing a secret that is not the last one). The suggested approach to tackle this issue was to use `for_each` to iterate over a map of secrets.

Version 0.5.0 has this implementation, but it's not backward compatible. Therefore you must migrate your Terraform code and the objects in the tfstate.

### Migrating the code:

Before 0.5.0 your secrets were defined as list as follow:

```
  secrets = [
    {
      name                    = "secret-1"
      description             = "My secret 1"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
    },
  ]

```

After version 0.5.0 you have to define you secrets as a map:

```
  secrets = {
    secret-1 = {
      description             = "My secret 1"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
    },
  }
```

Notice that the map key is the name of the secret, thefore a `name` field is not needed anymore.

### Migrating the objects in the tfstate file

To avoid recreating your already deploy secrets you can rename or move the object in the tfstate file as follow:

```
terraform state mv 'module.secrets-manager-1.aws_secretsmanager_secret_version.sm-sv['0']' 'module.secrets-manager-1.aws_secretsmanager_secret_version.sm-sv["secret-1"]'
```

Another option is to use a script to iterate over your secrets. In the [migration-scripts](/examples/migration-scripts) folder you'll find a couple of scripts that can be used as a starting point.

For example, to migrate a module named `secrets-manager-1` run the script as follow:

```
$ ./secret_list_to_map.sh secrets-manager-1

Move "module.secrets-manager-1.aws_secretsmanager_secret.sm[0]" to "module.secrets-manager-1.aws_secretsmanager_secret.sm[\"secret-1\"]"
Successfully moved 1 object(s).
Move "module.secrets-manager-1.aws_secretsmanager_secret_version.sm-sv[0]" to "module.secrets-manager-1.aws_secretsmanager_secret_version.sm-sv[\"secret-1\"]"
Successfully moved 1 object(s).
Move "module.secrets-manager-1.aws_secretsmanager_secret.sm[1]" to "module.secrets-manager-1.aws_secretsmanager_secret.sm[\"secret-2\"]"
Successfully moved 1 object(s).
Move "module.secrets-manager-1.aws_secretsmanager_secret_version.sm-sv[1]" to "module.secrets-manager-1.aws_secretsmanager_secret_version.sm-sv[\"secret-2\"]"
Successfully moved 1 object(s).

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.67.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.rsm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.sm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_rotation.rsm-sr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.rsm-sv](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.rsm-svu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.sm-sv](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.sm-svu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automatically_after_days"></a> [automatically\_after\_days](#input\_automatically\_after\_days) | Specifies the number of days between automatic scheduled rotations of the secret. Must be between 1 and 365 days. Example: 30 | `number` | `30` | no |
| <a name="input_ephemeral"></a> [ephemeral](#input\_ephemeral) | Enable ephemeral resources and write-only arguments to prevent sensitive data from being stored in state. Requires Terraform >= 1.11. When enabled, secret values use write-only arguments (\_wo) and are not persisted to state. Example: true | `bool` | `false` | no |
| <a name="input_recovery_window_in_days"></a> [recovery\_window\_in\_days](#input\_recovery\_window\_in\_days) | Specifies the number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. Example: 7 | `number` | `30` | no |
| <a name="input_rotate_secrets"></a> [rotate\_secrets](#input\_rotate\_secrets) | Map of secrets to keep and rotate in AWS Secrets Manager. Each secret must include rotation\_lambda\_arn. Example: { mysecret = { description = "My secret", secret\_string = "secret-value", rotation\_lambda\_arn = "arn:aws:lambda:us-east-1:123456789012:function:my-function" } } | `any` | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secrets to keep in AWS Secrets Manager. Example: { mysecret = { description = "My secret", secret\_string = "secret-value" } } | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Key-value map of user-defined tags attached to the secret. Keys cannot start with 'aws:'. Example: { Environment = "prod", Owner = "team" } | `any` | `{}` | no |
| <a name="input_unmanaged"></a> [unmanaged](#input\_unmanaged) | Terraform must ignore secrets lifecycle. Using this option you can initialize the secrets and rotate them outside Terraform, avoiding other users changing or rotating secrets by subsequent Terraform runs. Example: true | `bool` | `false` | no |
| <a name="input_version_stages"></a> [version\_stages](#input\_version\_stages) | List of version stages to be handled. Valid values are 'AWSCURRENT' and 'AWSPENDING'. Kept as null for backwards compatibility. Example: ["AWSCURRENT"] | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rotate_secret_arns"></a> [rotate\_secret\_arns](#output\_rotate\_secret\_arns) | Map of rotating secret names to their ARNs. Use these ARNs to grant permissions or reference rotating secrets in IAM policies and other AWS resources. |
| <a name="output_rotate_secret_ids"></a> [rotate\_secret\_ids](#output\_rotate\_secret\_ids) | Map of rotating secret names to their resource IDs. Use these IDs to reference rotating secrets in other Terraform resources. |
| <a name="output_secret_arns"></a> [secret\_arns](#output\_secret\_arns) | Map of secret names to their ARNs. Use these ARNs to grant permissions or reference secrets in IAM policies and other AWS resources. |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | Map of secret names to their resource IDs. Use these IDs to reference secrets in other Terraform resources. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
