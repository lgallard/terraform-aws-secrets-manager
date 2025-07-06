# Testing Guide

This document describes the testing framework and approach for the terraform-aws-secrets-manager module.

## Overview

The module uses [Terratest](https://terratest.gruntwork.io/) for automated testing. Terratest is a Go library that provides patterns and helper functions for testing Terraform modules by deploying real infrastructure and validating it.

## Test Structure

### Test Organization

```
test/
├── go.mod                              # Go module dependencies
├── go.sum                              # Go module checksums
├── fixtures/                           # Test configurations
│   ├── basic/                         # Basic secrets test
│   ├── key-value/                     # Key-value secrets test
│   ├── binary/                        # Binary secrets test
│   └── validation/                    # Input validation test
├── secrets_manager_basic_test.go      # Basic functionality tests
├── secrets_manager_key_value_test.go  # Key-value secrets tests
├── secrets_manager_binary_test.go     # Binary secrets tests
└── secrets_manager_validation_test.go # Validation and edge case tests
```

### Test Fixtures

Each test fixture is a complete Terraform configuration that tests a specific aspect of the module:

- **basic**: Tests basic secrets creation with plaintext values
- **key-value**: Tests JSON key-value secrets
- **binary**: Tests binary secrets (e.g., SSH keys, certificates)
- **validation**: Tests input validation and boundary conditions

## Test Categories

### 1. Basic Functionality Tests (`secrets_manager_basic_test.go`)

- Creates multiple secrets with different configurations
- Verifies secret ARNs, names, and IDs are generated correctly
- Tests that secrets can be retrieved from AWS
- Validates secret values match expected values
- Checks secret metadata and descriptions

### 2. Key-Value Secrets Tests (`secrets_manager_key_value_test.go`)

- Tests creation of JSON key-value secrets
- Verifies the JSON structure is preserved
- Validates all expected keys are present
- Checks that values can be parsed correctly

### 3. Binary Secrets Tests (`secrets_manager_binary_test.go`)

- Tests binary secret creation (SSH keys, certificates)
- Verifies base64 encoding/decoding works correctly
- Tests that binary data is preserved through the round trip
- Includes unit tests for encoding validation

### 4. Validation Tests (`secrets_manager_validation_test.go`)

- Tests input validation rules
- Validates recovery window boundary conditions
- Tests invalid configurations fail appropriately
- Verifies error messages are meaningful

## Running Tests

### Prerequisites

1. **Go 1.21+**: Required for running Terratest
2. **Terraform**: Required for deploying test infrastructure
3. **AWS Credentials**: Configure with appropriate permissions
4. **AWS Permissions**: The test user/role needs permissions to:
   - Create and delete Secrets Manager secrets
   - Read secret values
   - Create and delete KMS keys (for encryption tests)

### Local Testing

```bash
# Navigate to test directory
cd test

# Install dependencies
go mod download

# Run all tests
go test -v -timeout 60m ./...

# Run specific test
go test -v -timeout 60m -run TestSecretsManagerBasic

# Run tests in parallel (faster)
go test -v -timeout 60m -parallel 4 ./...
```

### Environment Variables

Set these environment variables for testing:

```bash
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
```

Or use AWS CLI profiles:

```bash
export AWS_PROFILE=your-test-profile
```

### CI/CD Testing

The project includes GitHub Actions workflows for automated testing:

- **Test Workflow** (`.github/workflows/test.yml`):
  - Runs on PRs and pushes to main/master
  - Tests against multiple Terraform versions
  - Includes linting and security scanning
  - Requires AWS credentials in GitHub Secrets

#### Required GitHub Secrets

Configure these secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS access key for testing
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for testing

## Test Best Practices

### 1. Isolation

- Each test runs in parallel with unique resource names
- Tests clean up all resources after completion
- No shared state between tests

### 2. Naming Convention

- Test resources use random suffixes to avoid conflicts
- Format: `terratest-sm-{type}-{random-id}`
- Example: `terratest-sm-basic-abc123`

### 3. Error Handling

- Tests verify both positive and negative scenarios
- Invalid configurations should fail with meaningful errors
- Tests include proper error assertions

### 4. Resource Cleanup

- All tests use `defer terraform.Destroy()` for cleanup
- Failed tests still attempt cleanup
- No orphaned resources should remain after test runs

## Debugging Tests

### Verbose Output

Use `-v` flag for detailed test output:

```bash
go test -v -run TestSecretsManagerBasic
```

### Terraform Debug

Set Terraform debug environment variables:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
go test -v -run TestSecretsManagerBasic
```

### Preserving Resources for Debugging

To prevent cleanup and inspect resources:

1. Comment out the `defer terraform.Destroy()` line in the test
2. Run the test
3. Manually inspect resources in AWS Console
4. Clean up manually: `terraform destroy` in the fixture directory

### Common Issues

1. **AWS Permissions**: Ensure test credentials have sufficient permissions
2. **Resource Limits**: AWS has limits on secrets per region
3. **Timing Issues**: Some AWS operations are eventually consistent
4. **Cleanup Failures**: Manually clean up resources if tests fail to destroy

## Contributing Tests

When adding new tests:

1. Create appropriate test fixtures
2. Follow existing naming conventions
3. Add both positive and negative test cases
4. Include proper cleanup and error handling
5. Update this documentation if needed

### Test Guidelines

- Test one feature per test function
- Use descriptive test names
- Include assertions for all important outputs
- Test edge cases and error conditions
- Keep test fixtures minimal but complete

## Continuous Integration

The test suite is integrated with GitHub Actions and runs automatically on:

- Pull requests to main/master branches
- Pushes to main/master branches
- Manual workflow triggers

Test results are displayed in the GitHub UI with detailed logs for debugging failures.