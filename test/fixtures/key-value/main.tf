module "secrets_manager" {
  source = "../../../"

  secrets = {
    "${var.test_name}-kv-secret" = {
      description = "Test key-value secret"
      secret_key_value = {
        username = "testuser"
        password = "testpassword"
        database = "testdb"
        host     = "localhost"
      }
      recovery_window_in_days = 7
    }
  }

  tags = {
    Environment = "test"
    TestRun     = var.test_name
    Terraform   = "true"
    SecretType  = "key-value"
  }
}
