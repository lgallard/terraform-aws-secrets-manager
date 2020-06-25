# terraform-aws-secrets-manager

```
module "secrets-manager" {

  source = "../terraform-aws-secrets-manager"

  secrets = [
    {
      name                    = "Secret1"
      description             = "My secret 1"
      recovery_window_in_days = 0
      secret_string           = "This is an example"
    }
  ]

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true

  }
}


```
