# Test Directory

This directory contains the Terratest-based testing framework for the terraform-aws-secrets-manager module.

## Quick Start

```bash
# Run all tests
make test

# Run specific test
make test-basic
```

## Structure

```
test/
├── fixtures/                          # Test configurations
│   ├── basic/                         # Basic secrets test
│   ├── key-value/                     # Key-value secrets test
│   ├── binary/                        # Binary secrets test
│   └── validation/                    # Input validation test
├── secrets_manager_basic_test.go      # Basic functionality tests
├── secrets_manager_key_value_test.go  # Key-value secrets tests
├── secrets_manager_binary_test.go     # Binary secrets tests
├── secrets_manager_validation_test.go # Validation tests
├── go.mod                             # Go module dependencies
└── README.md                          # This file
```

## Requirements

- Go 1.21+
- Terraform
- AWS credentials configured
- AWS permissions for Secrets Manager operations

## Documentation

See [../TESTING.md](../TESTING.md) for complete testing documentation.