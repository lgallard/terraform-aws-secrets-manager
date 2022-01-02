# Key-Value example
```
module "secrets-manager-2" {

  #source = "lgallard/secrets-manager/aws"
  source = "../../"

  secrets = {
    secret-kv-1 = {
      description = "This is a key/value secret"
      secret_key_value = {
        key1 = "value1"
        key2 = "value2"
      }
      recovery_window_in_days = 7
      policy                  = <<POLICY
				{
					"Version": "2012-10-17",
					"Statement": [
						{
							"Sid": "EnableAllPermissions",
							"Effect": "Allow",
							"Principal": {
								"AWS": "*"
							},
							"Action": "secretsmanager:GetSecretValue",
							"Resource": "*"
						}
					]
				}
				POLICY
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
      policy                  = null
    },
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }
}
```
