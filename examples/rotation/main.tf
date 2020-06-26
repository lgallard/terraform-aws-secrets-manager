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

