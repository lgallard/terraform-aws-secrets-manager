# This file demonstrates validation behavior
# Uncomment the module below to test validation error

# This should fail validation - missing secret_string_wo_version
# module "validation_test_fail" {
#   source = "../../"
#   
#   ephemeral = true
#   
#   secrets = {
#     invalid_secret = {
#       description = "This should fail validation"
#       secret_string = "test-value"
#       # Missing: secret_string_wo_version = 1
#     }
#   }
# }

# This should pass validation
module "validation_test_pass" {
  source = "../../"

  ephemeral = true

  secrets = {
    valid_secret = {
      description              = "This should pass validation"
      secret_string            = "test-value"
      secret_string_wo_version = 1
    }
  }
}