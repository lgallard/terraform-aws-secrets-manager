# Migration Example: From Regular to Ephemeral Secrets
# This file demonstrates how to migrate existing secrets to use ephemeral mode

# BEFORE: Regular secrets (stored in state)
# module "secrets_before" {
#   source = "../../"
#   
#   secrets = {
#     database_password = {
#       description = "Database password"
#       secret_string = var.db_password
#     }
#     
#     api_credentials = {
#       description = "API credentials"
#       secret_key_value = {
#         api_key = var.api_key
#         api_url = "https://api.example.com"
#       }
#     }
#   }
# }

# AFTER: Ephemeral secrets (NOT stored in state)
module "secrets_after" {
  source = "../../"

  # Enable ephemeral mode
  ephemeral = true

  secrets = {
    database_password = {
      description              = "Database password (ephemeral)"
      secret_string            = var.db_password
      secret_string_wo_version = 1 # Required for ephemeral mode
    }

    api_credentials = {
      description = "API credentials (ephemeral)"
      secret_key_value = {
        api_key = var.api_key
        api_url = "https://api.example.com"
      }
      secret_string_wo_version = 1 # Required for ephemeral mode
    }
  }

  tags = {
    Environment = "production"
    Migration   = "ephemeral"
  }
}

# Migration Steps:
# 1. Create new ephemeral configuration (above)
# 2. Run 'terraform plan' to see the changes (resources will be recreated)
# 3. Run 'terraform apply' to migrate to ephemeral mode
# 4. Verify that sensitive values are no longer in state file
#
# IMPORTANT: This migration will recreate the secret resources.
# Ensure you have the secret values available as the old state won't contain them after migration.

# Variables for demonstration (using main.tf variables)