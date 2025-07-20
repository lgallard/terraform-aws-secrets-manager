# Terraform AWS Secrets Manager Module - Development Guidelines

## Overview
This document outlines Terraform-specific development guidelines for the terraform-aws-secrets-manager module, focusing on best practices for AWS infrastructure as code.

## Module Structure & Organization

### File Organization
- **main.tf** - Primary resource definitions and locals
- **variables.tf** - Input variable definitions with validation
- **outputs.tf** - Output value definitions  
- **versions.tf** - Provider version constraints
- **iam.tf** - IAM roles and policies (for secret access)
- **notifications.tf** - SNS and notification configurations
- **rotation.tf** - Secret rotation configurations
- **replica.tf** - Cross-region replication configurations
- **policy.tf** - Resource-based policy configurations

### Code Organization Principles
- Group related resources logically in separate files
- Use descriptive locals for complex expressions
- Maintain backward compatibility with existing variable names
- Keep validation logic close to variable definitions

## Terraform Best Practices

### Resource Creation Patterns
**Favor `for_each` over `count`** for resource creation:

```hcl
# Preferred: Using for_each
resource "aws_secretsmanager_secret" "this" {
  for_each = var.enabled ? var.secrets : {}
  
  name = each.value.name
  # ...
}

# Avoid: Using count when for_each is more appropriate
resource "aws_secretsmanager_secret" "this" {
  count = var.enabled ? length(var.secrets) : 0
  # ...
}
```

### Variables & Validation
Use validation blocks for critical inputs where appropriate:

```hcl
# Example: Basic validation for naming conventions
variable "secret_name" {
  description = "Name of the secret to create"
  type        = string
  default     = null

  validation {
    condition     = var.secret_name == null ? true : can(regex("^[0-9A-Za-z-_/.]{1,512}$", var.secret_name))
    error_message = "The secret_name must be between 1 and 512 characters, contain only alphanumeric characters, hyphens, underscores, periods, and forward slashes."
  }
}
```

### Locals Organization
Structure locals for clarity and reusability:

```hcl
locals {
  # Resource creation conditions
  should_create_secret = var.enabled && var.secret_name != null
  should_create_replica = local.should_create_secret && length(var.replica_regions) > 0
  
  # Data processing
  secrets = concat(local.secret, var.secrets)
  
  # Validation helpers
  rotation_requirements_met = var.rotation_enabled && var.rotation_lambda_arn != null
}
```

## Testing Requirements

### Test Coverage for New Features
**Write tests when adding new features:**
- Create corresponding test files in `test/` directory
- Add example configurations in `examples/` directory
- Use Terratest for integration testing
- Test both success and failure scenarios

### Test Coverage for Modifications
**Add tests when modifying functionalities (if missing):**
- Review existing test coverage before making changes
- Add missing tests for functionality being modified
- Ensure backward compatibility is tested
- Test edge cases and error conditions

### Testing Strategy
- Use Terratest for integration testing
- Include examples for common use cases
- Test resource creation and destruction
- Validate outputs and state consistency
- Test different input combinations

## Testing Framework & CI/CD

### Test Structure
The testing framework is organized into the following components:

#### Test Directory Structure
```
test/
├── go.mod                          # Go module dependencies
├── go.sum                          # Go module checksums
├── helpers.go                      # Test helper functions
├── terraform_aws_secrets_manager_test.go    # Main integration tests
├── terraform_validation_test.go    # Validation and linting tests
├── terraform_ephemeral_test.go     # Ephemeral functionality tests
└── cleanup/
    └── main.go                     # Cleanup utility for test resources
```

#### Test Categories

**1. Validation Tests (`terraform_validation_test.go`)**
- `TestTerraformFormat` - Validates Terraform formatting
- `TestTerraformValidate` - Validates Terraform configuration syntax
- `TestExamplesValidation` - Validates all example configurations
- `TestTerraformPlan` - Tests that plan executes without errors
- `TestVariableValidation` - Tests input variable validation rules

**2. Integration Tests (`terraform_aws_secrets_manager_test.go`)**
- `TestTerraformAwsSecretsManagerBasic` - Basic module functionality
- `TestTerraformAwsSecretsManagerKeyValue` - Key-value secrets
- `TestTerraformAwsSecretsManagerRotation` - Secret rotation functionality
- `TestTerraformAwsSecretsManagerMultipleSecrets` - Multiple secrets creation
- `TestTerraformAwsSecretsManagerBinarySecret` - Binary secret handling
- `TestTerraformAwsSecretsManagerTags` - Tag functionality

**3. Ephemeral Tests (`terraform_ephemeral_test.go`)**
- `TestEphemeralVsRegularMode` - Compares ephemeral vs regular modes
- `TestEphemeralSecretTypes` - Different secret types in ephemeral mode
- `TestEphemeralSecretVersioning` - Version control in ephemeral mode
- `TestEphemeralRotatingSecrets` - Rotating secrets with ephemeral support

### Running Tests Locally

#### Prerequisites
```bash
# Install Go (version 1.21 or later)
go version

# Install Terraform (version 1.11 or later for ephemeral support)
terraform version

# Configure AWS credentials
aws configure
```

#### Test Execution Commands

**Run all tests:**
```bash
cd test
go test -v -timeout 45m ./...
```

**Run specific test suites:**
```bash
# Validation tests only (fast)
go test -v -timeout 10m -run "TestTerraform.*Validation|TestTerraformFormat"

# Ephemeral tests only
go test -v -timeout 30m -run "TestEphemeral.*"

# Integration tests only
go test -v -timeout 45m -run "TestTerraformAwsSecretsManager.*"
```

**Run tests with specific patterns:**
```bash
# Test ephemeral functionality
go test -v -run ".*Ephemeral.*"

# Test validation only
go test -v -run ".*Validation.*"
```

#### Test Environment Variables
```bash
export AWS_DEFAULT_REGION=us-east-1
export AWS_PROFILE=your-profile    # Optional
export TF_VAR_name_suffix=test-$(date +%s)  # Optional unique suffix
```

### CI/CD Pipeline

#### GitHub Actions Workflow (`.github/workflows/test.yml`)

The CI/CD pipeline includes the following jobs:

**1. Validate Job**
- Terraform format checking (`terraform fmt -check`)
- Terraform configuration validation
- Example configuration validation
- Runs on every push and pull request

**2. Security Job**
- Security scanning with `tfsec`
- Policy validation with `Checkov`
- SARIF report generation for GitHub Security tab
- Runs on every push and pull request

**3. Lint Job**
- Advanced linting with `TFLint`
- Custom rule checking via `.tflint.hcl`
- JUnit format reporting
- Runs on every push and pull request

**4. Unit Tests Job**
- Validation and ephemeral functionality tests
- Matrix strategy for parallel execution
- Artifact collection for test results
- Requires AWS credentials (secrets)
- Runs on pull requests and master branch

**5. Integration Tests Job**
- Full integration testing across multiple AWS regions
- Matrix strategy for regional testing
- Only runs on master branch or with `run-integration-tests` label
- Requires AWS credentials (secrets)

**6. Cleanup Job**
- Automatic cleanup of test resources
- Runs after test completion (success or failure)
- Prevents resource leakage and cost accumulation

#### Pipeline Triggers

**Every Push/PR:**
- Validation tests
- Security scanning
- Linting

**Pull Requests:**
- Unit tests (validation + ephemeral)

**Master Branch:**
- Full integration tests
- Multi-region testing

**Manual Trigger:**
- Add `run-integration-tests` label to PR for full testing

### Test Helper Functions

#### Common Utilities (`helpers.go`)
```go
// Generate unique test names
GenerateTestName(prefix string) string

// Get stable test regions
GetTestRegion(t *testing.T) string

// Validate secrets exist in AWS
ValidateSecretExists(t *testing.T, region, secretName string)

// Check secret values
ValidateSecretValue(t *testing.T, region, secretName string) string

// Validate tags
ValidateSecretTags(t *testing.T, region, secretName string, expectedTags map[string]string)

// State validation
ValidateNoSensitiveDataInState(t *testing.T, stateContent string, sensitiveValues []string)

// Configuration builders
CreateBasicSecretConfig(secretName, secretValue string) map[string]interface{}
CreateEphemeralSecretConfig(secretName, secretValue string, version int) map[string]interface{}
CreateKeyValueSecretConfig(secretName string, keyValues map[string]string) map[string]interface{}
```

### Security Testing

#### Ephemeral Mode Security Validation
The test suite includes specific checks to ensure ephemeral mode prevents sensitive data leakage:

```go
// Validate that sensitive values are NOT in Terraform state
ValidateNoSensitiveDataInState(t, stateString, []string{
    "supersecretpassword",
    "sensitive-value",
})
```

#### State File Analysis
Tests automatically analyze Terraform state files to ensure:
- Sensitive values are not persisted when `ephemeral = true`
- Write-only parameters are used correctly
- Version parameters control updates properly

### Test Resource Management

#### Automatic Cleanup
The testing framework includes comprehensive cleanup procedures:

**During Tests:**
- Automatic resource destruction via `defer terraform.Destroy()`
- Test isolation with unique naming
- Region-specific resource management

**After CI/CD Runs:**
- Automated cleanup job removes orphaned resources
- Tag-based cleanup for comprehensive coverage
- Cost optimization through proactive resource management

**Manual Cleanup:**
```bash
cd test
go run cleanup/main.go
```

### Best Practices for Test Development

#### Test Naming Conventions
- Use descriptive test names: `TestEphemeralVsRegularMode`
- Group related tests: `TestTerraformAwsSecretsManager*`
- Include test type in name: `*Validation`, `*Integration`, `*Ephemeral`

#### Test Structure
```go
func TestFeatureName(t *testing.T) {
    t.Parallel() // Enable parallel execution
    
    uniqueID := GenerateTestName("feature")
    awsRegion := GetTestRegion(t)
    
    terraformOptions := &terraform.Options{
        TerraformDir: "../",
        Vars: map[string]interface{}{
            // Test configuration
        },
        EnvVars: map[string]string{
            "AWS_DEFAULT_REGION": awsRegion,
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    
    // Test implementation
    terraform.InitAndApply(t, terraformOptions)
    
    // Assertions and validations
}
```

#### Error Handling
- Use `require` for critical assertions that should stop test execution
- Use `assert` for non-critical validations
- Include descriptive error messages
- Test both success and failure scenarios

### Performance Optimization

#### Parallel Test Execution
- All tests use `t.Parallel()` for concurrent execution
- Matrix strategies in CI/CD for parallel job execution
- Regional distribution for integration tests

#### Resource Efficiency
- Unique test naming prevents conflicts
- Automatic cleanup prevents resource accumulation
- Optimized test ordering (fast tests first)

#### Caching
- Go module caching in CI/CD
- Terraform provider caching
- Docker layer caching where applicable

## Security Considerations

### General Security Practices
- Consider encryption requirements (KMS keys, etc.)
- Follow principle of least privilege for IAM
- Implement proper access controls
- Use secure defaults where possible

### Example Security Patterns
```hcl
# Example: KMS key validation (optional)
variable "secret_kms_key_arn" {
  description = "The server-side encryption key for secrets"
  type        = string
  default     = null

  validation {
    condition     = var.secret_kms_key_arn == null ? true : can(regex("^arn:aws:kms:", var.secret_kms_key_arn))
    error_message = "The secret_kms_key_arn must be a valid KMS key ARN."
  }
}
```

## Module Development Guidelines

### Backward Compatibility
- Maintain existing variable interfaces when possible
- Use deprecation warnings for old patterns
- Provide migration guidance for breaking changes
- Document version-specific changes

### Code Quality
- Run `terraform fmt` before committing
- Use `terraform validate` to check syntax
- Consider pre-commit hooks for automated checks
- Use consistent naming conventions

## Specific Module Patterns

### Multi-Secret Support
Handle different input formats gracefully:

```hcl
# Support both legacy and new secret formats
secret_configurations = flatten([
  var.secret_configurations,
  [for secret in try(tolist(var.secrets), []) : try(secret.config, [])],
  [for k, secret in try(tomap(var.secrets), {}) : try(secret.config, [])],
  [for secret in var.secret_definitions : try(secret.config, [])],
  [for group in var.secret_groups : flatten([for secret in try(group.secrets, []) : try(secret.config, [])])]
])
```

### Using for_each for Complex Resources
```hcl
# Example: Creating multiple secret replicas
resource "aws_secretsmanager_secret_replica" "this" {
  for_each = {
    for idx, replica in var.secret_replicas : 
    "${replica.region}_${idx}" => replica
  }
  
  secret_id = aws_secretsmanager_secret.this[each.value.secret_name].id
  region    = each.value.region
  
  dynamic "kms_key_id" {
    for_each = each.value.kms_key_id != null ? [1] : []
    content {
      kms_key_id = each.value.kms_key_id
    }
  }
}
```

## Development Workflow

### Pre-commit Requirements
- Run `terraform fmt` on modified files
- Execute `terraform validate`
- Run tests for affected functionality
- Consider running security scanning tools
- Update documentation for variable changes

### Release Management
- **DO NOT manually update CHANGELOG.md** - we use release-please for automated changelog generation
- Use conventional commit messages for proper release automation
- Follow semantic versioning principles in commit messages

### Documentation Standards
- Document all variables with clear descriptions
- Include examples for complex variable structures
- Update README.md for new features
- Let release-please handle version history

## Common Patterns to Consider

1. **Prefer for_each** - Use `for_each` over `count` for better resource management
2. **Test Coverage** - Write tests for new features and missing test coverage
3. **Flexible Inputs** - Support multiple input formats where reasonable
4. **Validation Balance** - Add validation where it prevents common errors
5. **Consistent Naming** - Follow established naming conventions
6. **Resource Management** - Handle resource creation conflicts gracefully
7. **Backward Compatibility** - Maintain compatibility when possible
8. **Security Defaults** - Use secure defaults where appropriate

## Provider Version Management

```hcl
# Example provider configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"

    }
  }
}
```

*Note: Version constraints should be chosen based on actual requirements and compatibility needs.*