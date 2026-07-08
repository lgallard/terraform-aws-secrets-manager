# Rotation example
```
# Resource policy applied to the primary rotating secret and, via
# replicate_policy, to every replica region as well.
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
      policy                  = data.aws_iam_policy_document.secret_policy.json
      replicate_policy        = true
      replica_regions = {
        us-west-2 = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
        eu-west-1 = {
          region     = "eu-west-1"
          kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/87654321-4321-4321-4321-210987654321"
        }
      }
    },
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }

}
```

Rotating secrets support `replica_regions` and `replicate_policy` using the same input shape as regular `secrets`. Because the same policy document is applied in every region, use region-agnostic statements such as `resources = ["*"]` instead of hardcoding the primary secret ARN. If you previously set `replica_regions` under `rotate_secrets`, upgrading to this version will begin managing those replicas instead of ignoring that attribute.

# Lambda to rotate secrets

AWS templates are available at https://github.com/aws-samples/aws-secrets-manager-rotation-lambdas.

```hcl
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
