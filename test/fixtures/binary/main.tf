module "secrets_manager" {
  source = "../../../"

  secrets = {
    "${var.test_name}-binary-secret" = {
      description             = "Test binary secret"
      secret_binary           = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDt4TcI58h4G0wR+GcDY+0VJR10JNvG92jEKGaKxeMaOkfsXflVGsYXbfVBBCG/n3uHtTse7baYLB6LWQAuYWL1SHJVhhTQ7pPiocFWibAvJlVo1l7qJEDu2OxKpWEleCE+p3ufNXAy7v5UFO7EOnj0Zg6R3F/MiAWbQnaEHcYzNtogyC24YBecBLrBXZNi1g0AN1hM9k+3XvWUYTf9vPv8LIWnqo7y4Q2iEGWWurf37YFl1LzX4mG/Co+Vfe5TlZSe2YPMYWlw0ZKaK test@example.com"
      recovery_window_in_days = 7
    }
  }

  tags = {
    Environment = "test"
    TestRun     = var.test_name
    Terraform   = "true"
    SecretType  = "binary"
  }
}