# Terraform AWS Secrets Manager - Testing Guide

This directory contains comprehensive tests for the terraform-aws-secrets-manager module, including validation tests, integration tests, and specialized tests for ephemeral functionality.

## Quick Start

### Prerequisites

1. **Go 1.21+**
   ```bash
   go version
   ```

2. **Terraform 1.11+** (for ephemeral support)
   ```bash
   terraform version
   ```

3. **AWS Credentials**
   ```bash
   aws configure
   # OR
   export AWS_ACCESS_KEY_ID=your-key
   export AWS_SECRET_ACCESS_KEY=your-secret
   export AWS_DEFAULT_REGION=us-east-1
   ```

### Run All Tests

```bash
cd test
go test -v -timeout 45m ./...
```

## Test Categories

### 1. Validation Tests (Fast - ~2 minutes)

Tests that don't require AWS resources:

```bash
go test -v -timeout 10m -run "TestTerraform.*Validation|TestTerraformFormat|TestTerraformValidate|TestExamplesValidation"
```

**What it tests:**
- Terraform configuration syntax
- Variable validation rules
- Example configurations
- Format compliance
- Input validation logic

### 2. Ephemeral Tests (Medium - ~15 minutes)

Tests specific to ephemeral functionality:

```bash
go test -v -timeout 30m -run "TestEphemeral.*"
```

**What it tests:**
- Ephemeral vs regular mode comparison
- State file security (no sensitive data leakage)
- Different secret types in ephemeral mode
- Version control mechanisms
- Write-only parameter usage

### 3. Integration Tests (Slow - ~30 minutes)

Full integration tests with AWS resources:

```bash
go test -v -timeout 45m -run "TestTerraformAwsSecretsManager.*"
```

**What it tests:**
- End-to-end module functionality
- Multiple secret types (plaintext, key-value, binary)
- Secret rotation capabilities
- Tag management
- Cross-region functionality

## Test Organization

### File Structure

```
test/
├── go.mod                                 # Go dependencies
├── go.sum                                 # Dependency checksums
├── helpers.go                             # Shared utilities
├── terraform_validation_test.go           # Format/syntax validation
├── terraform_ephemeral_test.go           # Ephemeral functionality
├── terraform_aws_secrets_manager_test.go # Integration tests
├── cleanup/
│   └── main.go                           # Resource cleanup utility
└── README.md                             # This file
```

### Helper Functions

The `helpers.go` file provides utilities for:

- **Test naming:** `GenerateTestName(prefix)`
- **AWS regions:** `GetTestRegion(t)`
- **Secret validation:** `ValidateSecretExists()`, `ValidateSecretValue()`
- **State analysis:** `ValidateNoSensitiveDataInState()`
- **Config builders:** `CreateBasicSecretConfig()`, `CreateEphemeralSecretConfig()`

## Specific Test Scenarios

### Testing Ephemeral Mode

Ephemeral mode is the key security feature that prevents sensitive data from being stored in Terraform state:

```bash
# Test ephemeral vs regular mode comparison
go test -v -run "TestEphemeralVsRegularMode"

# Test different secret types in ephemeral mode
go test -v -run "TestEphemeralSecretTypes"

# Test version control in ephemeral mode
go test -v -run "TestEphemeralSecretVersioning"
```

### Testing Validation Rules

Variable validation ensures proper input handling:

```bash
# Test all validation rules
go test -v -run "TestVariableValidation"

# Test specific validation cases
go test -v -run "TestVariableValidation/ephemeral_missing_version"
go test -v -run "TestVariableValidation/invalid_secret_name"
```

### Testing Multiple Secret Types

```bash
# Test key-value secrets
go test -v -run "TestTerraformAwsSecretsManagerKeyValue"

# Test binary secrets
go test -v -run "TestTerraformAwsSecretsManagerBinarySecret"

# Test multiple secrets at once
go test -v -run "TestTerraformAwsSecretsManagerMultipleSecrets"
```

## Environment Configuration

### Required Environment Variables

```bash
export AWS_DEFAULT_REGION=us-east-1
```

### Optional Environment Variables

```bash
export AWS_PROFILE=your-profile                    # Use specific AWS profile
export TF_VAR_name_suffix=test-$(date +%s)        # Unique suffix for resources
export TERRATEST_REGION=us-west-2                 # Override test region
```

### Test Isolation

Each test automatically generates unique resource names to prevent conflicts:

```go
uniqueID := GenerateTestName("test-prefix")  // Generates: test-prefix-abc123
```

## Debugging Tests

### Verbose Output

```bash
go test -v -run "TestName"
```

### Keep Resources for Investigation

Temporarily comment out the cleanup:

```go
// defer terraform.Destroy(t, terraformOptions)  // Comment this line
```

### Debug Specific Test Cases

```bash
go test -v -run "TestVariableValidation/ephemeral_missing_version"
```

### View Terraform Logs

```bash
export TF_LOG=DEBUG
go test -v -run "TestName"
```

## Parallel Execution

Tests are designed to run in parallel for efficiency:

```bash
# All tests run in parallel by default
go test -v -parallel 8 ./...

# Limit parallelism if needed
go test -v -parallel 2 ./...
```

## Cleanup

### Automatic Cleanup

- Each test automatically cleans up its resources via `defer terraform.Destroy()`
- CI/CD pipeline includes a cleanup job for orphaned resources

### Manual Cleanup

If tests fail and leave resources behind:

```bash
cd test
go run cleanup/main.go
```

This utility removes:
- Test secrets matching known prefixes
- Secrets tagged as test resources
- Secrets created within the last 24 hours matching test patterns

## CI/CD Integration

### GitHub Actions

The tests integrate with GitHub Actions (`.github/workflows/test.yml`):

- **On every push/PR:** Validation, security, and linting
- **On PR to master:** Unit tests (validation + ephemeral)
- **On master branch:** Full integration tests
- **Manual trigger:** Add `run-integration-tests` label

### Local Testing Before CI

Run the same checks locally:

```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform init && terraform validate

# Security scan (if tfsec installed)
tfsec .

# Unit tests
cd test && go test -v -timeout 30m -run "TestTerraform.*Validation|TestEphemeral.*"
```

## Common Issues & Solutions

### Issue: AWS Credentials

**Error:** `NoCredentialProviders: no valid providers in chain`

**Solution:**
```bash
aws configure
# OR
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

### Issue: Resource Conflicts

**Error:** `AlreadyExistsException: A resource with the ID X already exists`

**Solution:**
```bash
# Run cleanup
cd test && go run cleanup/main.go

# Or use unique suffix
export TF_VAR_name_suffix=test-$(date +%s)
```

### Issue: Timeout in Tests

**Error:** `Test timed out after 30m`

**Solution:**
```bash
# Increase timeout
go test -v -timeout 60m ./...
```

### Issue: Region-Specific Failures

**Error:** Test fails in specific regions

**Solution:**
```bash
# Test in specific region
export AWS_DEFAULT_REGION=us-west-2
go test -v -run "TestName"
```

### Issue: State File Analysis Fails

**Error:** Ephemeral tests fail state validation

**Solution:**
- Ensure Terraform >= 1.11 for ephemeral support
- Check that `ephemeral = true` is set in test configuration
- Verify `secret_string_wo_version` is provided

## Performance Tips

### Speed Up Tests

1. **Run validation tests first** (fastest feedback):
   ```bash
   go test -v -run "TestTerraform.*Validation"
   ```

2. **Use parallel execution**:
   ```bash
   go test -v -parallel 8 ./...
   ```

3. **Target specific functionality**:
   ```bash
   go test -v -run "TestEphemeral.*"
   ```

### Resource Optimization

1. **Use consistent regions** to leverage provider caching
2. **Clean up regularly** to avoid hitting service limits
3. **Use small secret values** to reduce transfer time

## Contributing

### Adding New Tests

1. **Follow naming conventions:**
   - `TestTerraformAwsSecretsManager*` for integration tests
   - `TestEphemeral*` for ephemeral functionality
   - `TestTerraform*Validation` for validation tests

2. **Use helper functions:**
   ```go
   uniqueID := GenerateTestName("new-feature")
   config := CreateBasicSecretConfig("secret-name", "secret-value")
   ```

3. **Include cleanup:**
   ```go
   defer terraform.Destroy(t, terraformOptions)
   ```

4. **Enable parallel execution:**
   ```go
   t.Parallel()
   ```

5. **Add descriptive assertions:**
   ```go
   assert.Equal(t, expected, actual, "Secret value should match expected")
   ```

### Test Coverage Guidelines

- **New features:** Must include tests
- **Bug fixes:** Should include regression tests
- **Modifications:** Add tests if missing
- **Security features:** Require security-specific tests

## Security Considerations

### Ephemeral Testing

The ephemeral tests specifically validate:
- Sensitive data is NOT stored in Terraform state
- Write-only arguments work correctly
- Version parameters control updates
- Secrets are properly created in AWS despite state protection

### Test Data

- Use non-sensitive test values only
- Avoid real credentials or production data
- Use short-lived test resources
- Implement proper cleanup procedures

## Support

For test-related issues:

1. Check this README for common solutions
2. Review test output for specific error messages
3. Run cleanup utility if resource conflicts occur
4. Ensure proper AWS credentials and permissions
5. Verify Terraform and Go versions meet requirements

For ephemeral functionality questions, see:
- `examples/ephemeral/README.md`
- Main module documentation
- Test cases in `terraform_ephemeral_test.go`