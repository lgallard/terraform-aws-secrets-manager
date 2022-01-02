module "secrets-manager-1" {

  #source = "lgallard/secrets-manager/aws"
  source = "../../"

  secrets = {
    secret-1 = {
      description             = "My secret 1"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
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
    secret-2 = {
      description             = "My secret 2"
      recovery_window_in_days = 7
      secret_string           = "This is another example"
      policy                  = null
    }
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true

  }
}
