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

# Lambda to rotate secrets
# AWS temaplates available here https://github.com/aws-samples/aws-secrets-manager-rotation-lambdas)
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
