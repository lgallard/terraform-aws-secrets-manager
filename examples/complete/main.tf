# Complete example demonstrating all module features
# This example shows how to use the enhanced code quality features

module "secrets_manager" {
  source = "../../"

  # Enhanced tagging strategy
  default_tags = {
    Environment  = "production"
    ManagedBy    = "terraform"
    Project      = "secrets-management"
    Owner        = "platform-team"
  }

  tags = {
    Module    = "secrets-manager"
    Version   = "v1.0"
  }

  # Regular secrets with comprehensive configuration
  secrets = {
    database_credentials = {
      name        = "production/database/credentials"
      description = "Database connection credentials for production"
      kms_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      secret_key_value = {
        username = "admin"
        password = "super-secret-password"
        host     = "db.example.com"
        port     = "5432"
        database = "production"
      }
      tags = {
        SecretType = "database"
        Critical   = "true"
      }
      replica_regions = {
        us-west-2 = {
          region     = "us-west-2"
          kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/87654321-4321-4321-4321-210987654321"
        }
      }
    }

    api_key = {
      name_prefix = "production/api/"
      description = "Third-party API key"
      secret_string = "api-key-value-here"
      tags = {
        SecretType = "api-key"
        Service    = "external-api"
      }
    }

    ssl_certificate = {
      name           = "production/ssl/certificate"
      description    = "SSL certificate for production domain"
      secret_binary  = file("${path.module}/certificate.pem")
      tags = {
        SecretType = "certificate"
        Domain     = "example.com"
      }
    }
  }

  # Rotating secrets with Lambda function
  rotate_secrets = {
    database_password = {
      name                     = "production/database/rotating-password"
      description              = "Auto-rotating database password"
      secret_string           = "initial-password"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123456789012:function:rotate-db-password"
      automatically_after_days = 30
      tags = {
        SecretType = "rotating-password"
        Critical   = "true"
      }
    }
  }

  # Reference existing secrets as data sources
  existing_secrets = {
    legacy_secret = "legacy/application/config"
    imported_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:imported-secret-AbCdEf"
  }

  # Version stages for secret versions
  version_stages = ["AWSCURRENT"]

  # Global recovery window
  recovery_window_in_days = 7
}

# Example outputs showing how to use the enhanced outputs
output "all_secret_information" {
  description = "Complete information about all secrets"
  value = {
    secrets         = module.secrets_manager.secrets
    rotate_secrets  = module.secrets_manager.rotate_secrets
    existing_secrets = module.secrets_manager.existing_secrets
    all_arns        = module.secrets_manager.all_secret_arns
  }
  sensitive = true
}

output "secret_references_for_other_resources" {
  description = "Secret ARNs for use in other resources like IAM policies"
  value = {
    database_secret_arn = module.secrets_manager.secret_arns["database_credentials"]
    api_key_arn        = module.secrets_manager.secrets["api_key"].arn
    all_secret_arns    = module.secrets_manager.all_secret_arns
  }
}

output "rotation_status" {
  description = "Information about secret rotation configurations"
  value       = module.secrets_manager.secret_rotations
}

# Example of using secrets in other resources
resource "aws_iam_policy" "secrets_access" {
  name        = "secrets-access-policy"
  description = "Policy for accessing managed secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = module.secrets_manager.all_secret_arns
      }
    ]
  })

  tags = module.secrets_manager.secrets["database_credentials"].tags
}