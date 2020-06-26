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

