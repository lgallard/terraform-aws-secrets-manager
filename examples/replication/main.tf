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
      force_overwrite_replica_secret = true
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
      force_overwrite_replica_secret = false
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
