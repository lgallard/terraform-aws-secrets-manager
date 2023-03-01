![Terraform](https://lgallardo.com/images/terraform.jpg)
# terraform-aws-secrets-manager

Terraform module to create [Amazon Secrets Manager](https://aws.amazon.com/secrets-manager/) resources.

AWS Secrets Manager helps you protect secrets needed to access your applications, services, and IT resources. The service enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle.

## Examples

Check the [examples](/examples/) folder where you can see the complete compilation of snippets.

## Usage

You can create secrets for plain texts, keys/values and binary data:

### Plain text secrets

```
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

```
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

```
module "secrets-manager-3" {

  source = "lgallard/secrets-manager/aws"

  secrets = {
    secret-binary-1 = {
      description   = "This is a binary secret"
      secret_binary = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDt4TcI58h4G0wR+GcDY+0VJR10JNvG92jEKGaKxeMaOkfsXflVGsYXbfVBBCG/n3uHtTse7baYLB6LWQAuYWL1SHJVhhTQ7pPiocFWibAvJlVo1l7qJEDu2OxKpWEleCE+p3ufNXAy7v5UFO7EOnj0Zg6R3F/MiAWbQnaEHcYzNtogyC24YBecBLrBXZNi1g0AN1hM9k+3XvWUYTf9vPv8LIWnqo7y4Q2iEGWWurf37YFl1LzX4mG/Co+Vfe5TlZSe2YPMYWlw0ZKaKvwzInRR6dPMAflo3ABzlduiIbSdp110uGqB8i2M8eGXNDxR7Ni4nnLWnT9r1cpWhXWP6pAG4Xg8+x7+PIg/pgjgJNmsURw+jPD6+hkCw2Vz16EIgkC2b7lj0V6J4LncUoRzU/1sAzCQ4tspy3SKBUinYoxbDvXleF66FHEjfparnvNwfslBx0IJjG2uRwuX6zrsNIsGF1stEjz+eyAOtFV4/wRjRcCNDZvl1ODzIvwf8pAWddE= lgallard@server1"
    },
    secret-binary-2 = {
      description             = "This is a binary secret"
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
## Secrets Rotation

If you need to rotate your secrets, use `rotate_secrets` map to define them. Take into account that the lambda function must exist and it must have the right permissions to rotate the secrets in AWS Secret manager:


```
module "secrets-manager-4" {

  #source = "lgallard/secrets-manager/aws"
  source = "../../"

  rotate_secrets = {
    secret-rotate-1 = {
      description             = "This is a secret to be rotated by a lambda"
      secret_string           = "This is an example"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123455678910:function:lambda-rotate-secret"
      recovery_window_in_days = 15
    },
    secret-rotate-2 = {
      description             = "This is another secret to be rotated by a lambda"
      secret_string           = "This is another example"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123455678910:function:lambda-rotate-secret"
      recovery_window_in_days = 7
    },
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }

}

# Lambda to rotate secrets
# AWS temaplates available here https://github.com/aws-samples/aws-secrets-manager-rotation-lambdas
module "rotate_secret_lambda" {
  source  = "spring-media/lambda/aws"
  version = "5.2.0"

  filename         = "secrets_manager_rotation.zip"
  function_name    = "secrets-manager-rotation"
  handler          = "secrets_manager_rotation.lambda_handler"
  runtime          = "python3.7"
  source_code_hash = filebase64sha256("${path.module}/secrets_manager_rotation.zip")

  environment = {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.us-east-1.amazonaws.com"
    }
  }

}

resource "aws_lambda_permission" "allow_secret_manager_call_Lambda" {
  function_name = module.rotate_secret_lambda.function_name
  statement_id  = "AllowExecutionSecretManager"
  action        = "lambda:InvokeFunction"
  principal     = "secretsmanager.amazonaws.com"
}
```

## Several secret definitions

You can define different type of secrets (string, key/value or binary) in the same `secrets` or `rotate_secrets` map:

```
module "secrets-manager-5" {

  source = "lgallard/secrets-manager/aws"

  secrets = {
    secret-plain = {
      description             = "My plain text secret"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
    },
    secret-key-value = {
      description = "This is a key/value secret"
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

## Secrets replication

You can define different type of secrets (string, key/value or binary) in the same `secrets` or `rotate_secrets` map:

```
module "secrets-manager-6" {

  source = "lgallard/secrets-manager/aws"

  secrets = {
    secret-plain = {
      description             = "My plain text secret"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
      replica_regions = {
        us-west-2 = "arn:aws:kms:us-west-2:1234567890:key/12345678-1234-1234-1234-123456789012"
      }
    },
    secret-key-value = {
      description = "This is a key/value secret"
      secret_key_value = {
        username = "user"
        password = "topsecret"
      }
      replica_regions = {
        us-west-1 = "arn:aws:kms:us-west-1:1234567890:key/12345678-1234-1234-1234-123456789012"
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.67.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.56.0 |

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
| <a name="input_automatically_after_days"></a> [automatically\_after\_days](#input\_automatically\_after\_days) | Specifies the number of days between automatic scheduled rotations of the secret. | `number` | `30` | no |
| <a name="input_recovery_window_in_days"></a> [recovery\_window\_in\_days](#input\_recovery\_window\_in\_days) | Specifies the number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. | `number` | `30` | no |
| <a name="input_rotate_secrets"></a> [rotate\_secrets](#input\_rotate\_secrets) | Map of secrets to keep and rotate in AWS Secrets Manager | `any` | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secrets to keep in AWS Secrets Manager | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Specifies a key-value map of user-defined tags that are attached to the secret. | `any` | `{}` | no |
| <a name="input_unmanaged"></a> [unmanaged](#input\_unmanaged) | Terraform must ignore secrets lifecycle. Using this option you can initialize the secrets and rotate them outside Terraform, thus, avoiding other users to change or rotate the secrets by subsequent runs of Terraform | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rotate_secret_arns"></a> [rotate\_secret\_arns](#output\_rotate\_secret\_arns) | Rotate secret arns map |
| <a name="output_rotate_secret_ids"></a> [rotate\_secret\_ids](#output\_rotate\_secret\_ids) | Rotate secret ids map |
| <a name="output_secret_arns"></a> [secret\_arns](#output\_secret\_arns) | Secrets arns map |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | Secret ids map |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
