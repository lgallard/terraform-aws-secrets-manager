module "secrets_manager" {
  source = "../../../"

  secrets = {
    "${var.test_name}-secret-1" = {
      description             = "Test secret 1"
      recovery_window_in_days = 7
      secret_string           = "test-value-1"
    },
    "${var.test_name}-secret-2" = {
      description             = "Test secret 2"
      recovery_window_in_days = 7
      secret_string           = "test-value-2"
    }
  }

  tags = {
    Environment = "test"
    TestRun     = var.test_name
    Terraform   = "true"
  }
}