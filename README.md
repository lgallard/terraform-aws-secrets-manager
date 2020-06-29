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

  secrets = [
    {
      name                    = "secret-1"
      description             = "My secret 1"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
    },
    {
      name                    = "secret-2"
      description             = "My secret 2"
      recovery_window_in_days = 7
      secret_string           = "This is another example"
    }
  ]

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

  secrets = [
   {
      name        = "secret-kv-1"
      description = "This is a key/value secret"
      secret_key_value = {
        key1 = "value1"
        key2 = "value2"
      }
      recovery_window_in_days = 7
    },
   {
      name        = "secret-kv-2"
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
 ]

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

  secrets = [
    {
      name                    = "secret-binary-1"
      description             = "This is a binary secret"
      secret_binary           = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDt4TcI58h4G0wR+GcDY+0VJR10JNvG92jEKGaKxeMaOkfsXflVGsYXbfVBBCG/n3uHtTse7baYLB6LWQAuYWL1SHJVhhTQ7pPiocFWibAvJlVo1l7qJEDu2OxKpWEleCE+p3ufNXAy7v5UFO7EOnj0Zg6R3F/MiAWbQnaEHcYzNtogyC24YBecBLrBXZNi1g0AN1hM9k+3XvWUYTf9vPv8LIWnqo7y4Q2iEGWWurf37YFl1LzX4mG/Co+Vfe5TlZSe2YPMYWlw0ZKaKvwzInRR6dPMAflo3ABzlduiIbSdp110uGqB8i2M8eGXNDxR7Ni4nnLWnT9r1cpWhXWP6pAG4Xg8+x7+PIg/pgjgJNmsURw+jPD6+hkCw2Vz16EIgkC2b7lj0V6J4LncUoRzU/1sAzCQ4tspy3SKBUinYoxbDvXleF66FHEjfparnvNwfslBx0IJjG2uRwuX6zrsNIsGF1stEjz+eyAOtFV4/wRjRcCNDZvl1ODzIvwf8pAWddE= lgallard@server1"
    },
    {
      name                    = "secret-binary-2"
      description             = "Another binary secret"
      secret_binary           = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzc818NSC6oJYnNjVWoF43+IuQpqc3WyS8BWZ50uawK5lY/aObweX2YiXPv2CoVvHUM0vG7U7BDBvNi2xwsT9n9uT27lcVQsTa8iDtpyoeBhcj3vJ60Jd04UfoMP7Og6UbD+KGiaqQ0LEtMXq6d3i619t7V0UkaJ4MXh2xl5y3bV4zNzTXdSScJnvMFfjLW0pJOOqltLma3NQ9ILVdMSK2Vzxc87T+h/jp0VuUAX4Rx9DqmxEU/4JadXmow/BKy69KVwAk/AQ8jL7OwD2YAxlMKqKnOsBJQF27YjmMD240UjkmnPlxkV8+g9b2hA0iM5GL+5MWg6pPUE0BYdarCmwyuaWYhv/426LnfHTz9UVC3y9Hg5c4X4I6AdJJUmarZXqxnMe9jJiqiQ+CAuxW3m0gIGsEbUul6raG73xFuozlaXq3J+kMCVW24eG2i5fezgmtiysIf/dpcUo+YLkX+U8jdMQg9IwCY0bf8XL39kwJ7u8uWU8+7nMcS9VQ5llVVMk= lgallard@server2"
      recovery_window_in_days = 7
      tags = {
        app = "web"
      }
    }

 ]

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }

}

```
## Secrets Rotation

If yo need to rotate your secrest, use `rotate_secrets` list to define them. Take into account that the lambda function must exist and it must have the right permissions to rotate the secrets in AWS Secret manager:


```
module "secrets-manager-4" {

  source = "lgallard/secrets-manager/aws"

    rotate_secrets = [
    {
      name                    = "secret-rotate-1"
      description             = "This is a secret to be rotated by a lambda"
      secret_string           = "This is an example"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123455678910:function:lambda-rotate-secret"
      recovery_window_in_days = 15
    },
    {
      name                    = "secret-rotate-2"
      description             = "This is another secret to be rotated by a lambda"
      secret_string           = "This is another example"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123455678910:function:lambda-rotate-secret"
      recovery_window_in_days = 7
    },
  ]

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }

}
```

## Several secret definitions

You can define different type of secrets (string, key/balue or binary) in the same `secrets` or `rotate_secrets` list:

```
module "secrets-manager-5" {

  source = "lgallard/secrets-manager/aws"

  secrets = [
    {
      name                    = "secret-plain"
      description             = "My plain text secret"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
    },
   {
      name        = "secret-key-value"
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
 ]

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }

}

```
## Providers

| Name | Version |
|------|---------|
| aws | >= 2.67.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| automatically\_after\_days | Specifies the number of days between automatic scheduled rotations of the secret. | `number` | `30` | no |
| recovery\_window\_in\_days | Specifies the number of days that AWS Secrets Manager waits before it can delete the secret. This value can be 0 to force deletion without recovery or range from 7 to 30 days. | `number` | `30` | no |
| rotate\_secrets | List of secrets to keep and rotate in AWS Secrets Manager | `any` | `[]` | no |
| secrets | List of secrets to keep in AWS Secrets Manager | `any` | `[]` | no |
| tags | Specifies a key-value map of user-defined tags that are attached to the secret. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| rotate\_secret\_arns | Rotate secret arn list |
| rotate\_secret\_ids | Rotate secret id list |
| secret\_arns | Secret arn list |
| secret\_ids | Secret id list |
