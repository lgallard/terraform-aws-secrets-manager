# Ephemeral Secrets Example
# This example demonstrates how to use ephemeral secrets to prevent sensitive data from being stored in state

# Variables for demonstration
variable "db_password" {
  description = "Database password (will be handled as ephemeral)"
  type        = string
  sensitive   = true
  default     = "super-secret-password"
}

variable "api_key" {
  description = "API key (will be handled as ephemeral)"
  type        = string
  sensitive   = true
  default     = "api-key-12345"
}

# Example with ephemeral resources (requires Terraform 1.11+)
# ephemeral "random_password" "db_password" {
#   length = 16
#   special = true
# }

# Regular ephemeral secrets
module "ephemeral_secrets" {
  source = "../../"

  # Enable ephemeral mode
  ephemeral = true

  secrets = {
    # String secret example
    database_password = {
      description              = "Database password (ephemeral)"
      secret_string            = var.db_password
      secret_string_wo_version = 1
    }

    # Key-value secret example
    api_credentials = {
      description = "API credentials (ephemeral)"
      secret_key_value = {
        api_key = var.api_key
        api_url = "https://api.example.com"
      }
      secret_string_wo_version = 1
    }

    # Binary secret example (SSH key)
    # Note: Binary secrets use secret_string_wo_version (stored as base64-encoded strings)
    ssh_private_key = {
      description              = "SSH private key (ephemeral)"
      secret_binary            = file("${path.module}/test_key.pem")
      secret_string_wo_version = 1
    }
  }

  tags = {
    Environment = "demo"
    Project     = "ephemeral-secrets"
    Security    = "high"
  }
}

# Example with rotation and ephemeral mode
module "ephemeral_rotate_secrets" {
  source = "../../"

  # Enable ephemeral mode
  ephemeral = true

  rotate_secrets = {
    rotating_db_password = {
      description              = "Rotating database password (ephemeral)"
      secret_string            = var.db_password
      secret_string_wo_version = 1
      rotation_lambda_arn      = "arn:aws:lambda:us-east-1:123456789012:function:rotate-secret"
      automatically_after_days = 30
    }
  }

  tags = {
    Environment = "demo"
    Project     = "ephemeral-secrets"
    Security    = "high"
    Rotation    = "enabled"
  }
}

# Example showing version increment for updates
module "ephemeral_secrets_v2" {
  source = "../../"

  # Enable ephemeral mode
  ephemeral = true

  secrets = {
    # To update this secret, increment the version
    updated_secret = {
      description              = "Secret that needs updating"
      secret_string            = "new-secret-value"
      secret_string_wo_version = 2 # Incremented from 1 to trigger update
    }
  }

  tags = {
    Environment = "demo"
    Project     = "ephemeral-secrets"
    Version     = "v2"
  }
}

# Example: Using with ephemeral resources (commented out as it requires Terraform 1.11+)
# module "ephemeral_with_random" {
#   source = "../../"
#   
#   ephemeral = true
#   
#   secrets = {
#     random_password = {
#       description = "Random password (ephemeral)"
#       secret_string = ephemeral.random_password.db_password.result
#       secret_string_wo_version = 1
#     }
#   }
# }