# Error Examples for Ephemeral Secrets
# These examples demonstrate common configuration errors and how to fix them

# ERROR EXAMPLE 1: Missing version parameter when ephemeral is enabled
# This will fail validation
# module "error_missing_version" {
#   source = "../../"
#   
#   ephemeral = true
#   
#   secrets = {
#     bad_secret = {
#       description = "This will fail - missing secret_string_wo_version"
#       secret_string = "some-secret"
#       # Missing: secret_string_wo_version = 1
#     }
#   }
# }
# Error: secret_string_wo_version is required and must be >= 1 when ephemeral is enabled.

# CORRECT VERSION:
module "correct_version" {
  source = "../../"

  ephemeral = true

  secrets = {
    good_secret = {
      description              = "This works - has required version parameter"
      secret_string            = "some-secret"
      secret_string_wo_version = 1 # Required when ephemeral = true
    }
  }
}

# ERROR EXAMPLE 2: Invalid version value (zero or negative)
# This will fail validation
# module "error_invalid_version" {
#   source = "../../"
#   
#   ephemeral = true
#   
#   secrets = {
#     bad_version = {
#       description = "This will fail - invalid version value"
#       secret_string = "some-secret"
#       secret_string_wo_version = 0  # Must be >= 1
#     }
#   }
# }
# Error: secret_string_wo_version is required and must be >= 1 when ephemeral is enabled.

# ERROR EXAMPLE 3: Using conflicting version parameters
# This will fail validation
# module "error_conflicting_versions" {
#   source = "../../"
#   
#   ephemeral = true
#   
#   secrets = {
#     conflicting_secret = {
#       description = "This will fail - conflicting version parameters"
#       secret_string = "some-secret"
#       secret_string_wo_version = 1
#       secret_binary_wo_version = 1  # Should not be used with secret_string_wo_version
#     }
#   }
# }
# Error: Cannot specify both secret_string_wo_version and secret_binary_wo_version for the same secret when ephemeral is enabled.

# ERROR EXAMPLE 4: Using ephemeral with incompatible Terraform version
# This will fail if using Terraform < 1.11
# The provider.tf should specify: required_version = ">= 1.11"

# ERROR EXAMPLE 5: Trying to use write-only parameters without ephemeral mode
# This configuration is valid but the write-only parameters will be ignored
module "ignored_wo_parameters" {
  source = "../../"

  ephemeral = false # Default value

  secrets = {
    regular_secret = {
      description              = "Regular secret - wo_version will be ignored"
      secret_string            = "some-secret"
      secret_string_wo_version = 1 # This will be ignored when ephemeral = false
    }
  }
}

# BEST PRACTICES EXAMPLES

# 1. Proper ephemeral configuration
module "best_practice_ephemeral" {
  source = "../../"

  ephemeral = true

  secrets = {
    # String secret
    app_password = {
      description              = "Application password (ephemeral)"
      secret_string            = var.app_password
      secret_string_wo_version = 1
    }

    # Key-value secret
    database_config = {
      description = "Database configuration (ephemeral)"
      secret_key_value = {
        username = var.db_username
        password = var.db_password # Uses db_password from main.tf
        host     = var.db_host
      }
      secret_string_wo_version = 1
    }

    # Binary secret (SSH key)
    ssh_key = {
      description              = "SSH private key (ephemeral)"
      secret_binary            = file("${path.module}/test_key.pem")
      secret_string_wo_version = 1 # Note: Use string version for binary too
    }
  }

  tags = {
    Environment = "production"
    Security    = "ephemeral"
    Compliance  = "required"
  }
}

# 2. Version increment for updates
module "version_increment_example" {
  source = "../../"

  ephemeral = true

  secrets = {
    updated_secret = {
      description              = "Secret that needs updating"
      secret_string            = var.new_secret_value
      secret_string_wo_version = 2 # Increment to trigger update
    }
  }
}

# Variables for examples (additional to main.tf variables)
variable "app_password" {
  description = "Application password"
  type        = string
  sensitive   = true
  default     = "app-secret-password"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dbuser"
}

variable "db_host" {
  description = "Database host"
  type        = string
  default     = "db.example.com"
}

variable "new_secret_value" {
  description = "New secret value for update example"
  type        = string
  sensitive   = true
  default     = "updated-secret-value"
}