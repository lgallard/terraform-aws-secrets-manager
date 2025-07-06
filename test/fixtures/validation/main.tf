module "secrets_manager" {
  source = "../../../"

  recovery_window_in_days = var.recovery_window

  secrets = {
    "${var.test_name}-validation-secret" = {
      description             = "Test validation secret"
      secret_string           = "test-validation-value"
      recovery_window_in_days = var.recovery_window
    }
  }

  tags = {
    Environment = "test"
    TestRun     = var.test_name
    Terraform   = "true"
    Purpose     = "validation"
  }
}
