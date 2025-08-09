# Terraform AWS Secrets Manager Module - Development Guidelines

## Overview
This document outlines Terraform-specific development guidelines for the terraform-aws-secrets-manager module, focusing on best practices for AWS infrastructure as code.

## Module Structure & Organization

### File Organization
- **main.tf** - Primary resource definitions and locals
- **variables.tf** - Input variable definitions with validation
- **outputs.tf** - Output value definitions  
- **versions.tf** - Provider version constraints

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
    condition     = var.secret_kms_key_arn == null ? true : can(regex("^(arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}|alias/[a-zA-Z0-9/_-]+|[a-f0-9-]{36})$", var.secret_kms_key_arn))
    error_message = "KMS key ID must be a valid KMS key ID, key ARN, or alias ARN."
  }
}
```

## Ephemeral Password Support

### Overview
The module supports ephemeral mode to prevent sensitive data from being stored in Terraform state files. This security feature uses write-only arguments (`_wo` parameters) and requires Terraform 1.11 or later.

### When to Use Ephemeral Mode

**Use ephemeral mode when:**
- Working with highly sensitive credentials (database passwords, API keys, certificates)
- Security compliance requires that secrets never appear in state files
- Working in environments where state files might be exposed or audited
- Integrating with ephemeral resources (e.g., `random_password`)

**Consider standard mode when:**
- Security requirements are less stringent
- State file security is already ensured through other means
- Working with Terraform versions < 1.11
- Need maximum compatibility with existing workflows

### Configuration Patterns

#### Standard vs Ephemeral Mode Comparison

**Standard Mode (Default):**
```hcl
module "secrets_manager" {
  source = "lgallard/secrets-manager/aws"
  
  secrets = {
    database_password = {
      description   = "Database password"
      secret_string = var.db_password
    }
  }
}
```

**Ephemeral Mode:**
```hcl
module "secrets_manager" {
  source = "lgallard/secrets-manager/aws"
  
  # Enable ephemeral mode
  ephemeral = true
  
  secrets = {
    database_password = {
      description              = "Database password (ephemeral)"
      secret_string            = var.db_password
      secret_string_wo_version = 1  # Required for ephemeral mode
    }
  }
}
```

#### Secret Types with Ephemeral Mode

**String Secrets:**
```hcl
secrets = {
  api_token = {
    description              = "API authentication token"
    secret_string            = var.api_token
    secret_string_wo_version = 1
  }
}
```

**Key-Value Secrets:**
```hcl
secrets = {
  database_credentials = {
    description = "Database connection details"
    secret_key_value = {
      username = "admin"
      password = var.db_password
      host     = "db.example.com"
      port     = "5432"
    }
    secret_string_wo_version = 1
  }
}
```

**Binary Secrets:**
```hcl
secrets = {
  ssl_certificate = {
    description              = "SSL private key"
    secret_binary            = file("${path.module}/private.key")
    secret_string_wo_version = 1  # Binary secrets use string version parameter
  }
}
```

**Rotating Secrets:**
```hcl
rotate_secrets = {
  rotating_password = {
    description              = "Auto-rotating database password"
    secret_string            = var.initial_password
    secret_string_wo_version = 1
    rotation_lambda_arn      = var.rotation_lambda_arn
    automatically_after_days = 30
  }
}
```

### Version Management

#### Version Control for Updates
Ephemeral secrets use version parameters to control when updates occur:

```hcl
# Initial deployment
secrets = {
  api_key = {
    description              = "API key"
    secret_string            = var.api_key
    secret_string_wo_version = 1
  }
}

# To update the secret, increment the version
secrets = {
  api_key = {
    description              = "API key"
    secret_string            = var.new_api_key
    secret_string_wo_version = 2  # Incremented to trigger update
  }
}
```

#### Version Requirements
- `secret_string_wo_version` must be >= 1
- Version increments trigger secret updates
- All secret types (string, key-value, binary) use `secret_string_wo_version`

### Migration from Standard to Ephemeral Mode

#### Migration Process
⚠️ **Important**: Migration will recreate secret resources and may cause brief service interruption.

**Before Migration:**
```hcl
module "secrets" {
  source = "lgallard/secrets-manager/aws"
  
  secrets = {
    database_password = {
      description   = "Database password"
      secret_string = var.db_password
    }
  }
}
```

**After Migration:**
```hcl
module "secrets" {
  source = "lgallard/secrets-manager/aws"
  
  ephemeral = true  # Enable ephemeral mode
  
  secrets = {
    database_password = {
      description              = "Database password (ephemeral)"
      secret_string            = var.db_password
      secret_string_wo_version = 1  # Add version parameter
    }
  }
}
```

#### Migration Steps
1. **Plan**: Run `terraform plan` to review changes (resources will be recreated)
2. **Backup**: Ensure secret values are backed up outside Terraform
3. **Apply**: Run `terraform apply` to migrate to ephemeral mode
4. **Verify**: Confirm sensitive values are not in state file

### Validation Requirements

#### Required Parameters
When `ephemeral = true`:
- `secret_string_wo_version` is required for all secrets
- Version value must be >= 1
- Only one version parameter type per secret

#### Variable Validation Examples
```hcl
variable "secrets" {
  type = map(object({
    description              = string
    secret_string            = optional(string)
    secret_string_wo_version = optional(number)
    # ... other fields
  }))
  
  validation {
    condition = alltrue([
      for k, v in var.secrets :
      var.ephemeral == false || (can(v.secret_string_wo_version) && try(v.secret_string_wo_version >= 1, false))
    ])
    error_message = "secret_string_wo_version is required and must be >= 1 when ephemeral is enabled."
  }
}
```

### Security Considerations

#### State File Protection
- **Ephemeral mode**: Sensitive values never appear in Terraform state
- **Write-only parameters**: Use `secret_string_wo` internally to prevent state persistence
- **Version control**: Updates controlled through version parameters, not value changes

#### Security Best Practices
```hcl
# Use sensitive variables for input
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true  # Mark as sensitive
}

# Enable ephemeral mode for sensitive secrets
module "secrets" {
  source = "lgallard/secrets-manager/aws"
  
  ephemeral = true
  
  secrets = {
    db_password = {
      description              = "Database password (ephemeral)"
      secret_string            = var.database_password
      secret_string_wo_version = 1
      kms_key_id              = aws_kms_key.secrets_key.arn  # Use KMS encryption
    }
  }
  
  tags = {
    Security    = "high"
    Compliance  = "required"
  }
}
```

#### State File Analysis
Test configurations should validate state security:

```go
// Validate that sensitive values are NOT in Terraform state
ValidateNoSensitiveDataInState(t, stateString, []string{
    "supersecretpassword",
    "sensitive-api-key",
})
```

### Advanced Usage Patterns

#### Integration with Ephemeral Resources
```hcl
# Generate ephemeral password
ephemeral "random_password" "db_password" {
  length  = 16
  special = true
}

# Use ephemeral password in secret
module "secrets_manager" {
  source = "lgallard/secrets-manager/aws"
  
  ephemeral = true
  
  secrets = {
    database_password = {
      description              = "Random database password (ephemeral)"
      secret_string            = ephemeral.random_password.db_password.result
      secret_string_wo_version = 1
    }
  }
}
```

#### Limitations with for_each
Due to Terraform architectural limitations, ephemeral values cannot be used with `for_each` in module calls. Use direct AWS resources instead:

```hcl
# Generate multiple ephemeral passwords
ephemeral "random_password" "db_passwords" {
  for_each = var.db_users
  length   = 24
  special  = true
}

# Create secrets directly (not through module)
resource "aws_secretsmanager_secret_version" "db_secret_versions" {
  for_each = var.db_users
  
  secret_id = aws_secretsmanager_secret.db_secrets[each.key].id
  
  secret_string_wo = jsonencode({
    username = each.key
    password = ephemeral.random_password.db_passwords[each.key].result
  })
  
  secret_string_wo_version = 1
}
```

### Testing Ephemeral Functionality

#### Test Structure
```bash
# Run ephemeral-specific tests
cd test
go test -v -timeout 30m -run "TestEphemeral.*"
```

#### Test Categories
- `TestEphemeralVsRegularMode` - Compares modes for security compliance
- `TestEphemeralSecretTypes` - Validates all secret types work in ephemeral mode
- `TestEphemeralSecretVersioning` - Tests version-controlled updates
- `TestEphemeralRotatingSecrets` - Validates rotation with ephemeral mode

#### Test Helper Functions
```go
// Create ephemeral secret configuration
CreateEphemeralSecretConfig(secretName, secretValue string, version int) map[string]interface{}

// Validate state security
ValidateNoSensitiveDataInState(t *testing.T, stateContent string, sensitiveValues []string)
```

### Requirements and Compatibility

#### Version Requirements
- **Terraform**: >= 1.11 (for ephemeral resource support)
- **AWS Provider**: >= 2.67.0
- **Module**: Latest version with ephemeral support

#### Backward Compatibility
- Default behavior (`ephemeral = false`) remains unchanged
- Existing configurations continue to work without modification
- Migration is opt-in and explicit

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
The module uses a simple map-based approach for managing multiple secrets:

```hcl
# Simple map structure for secrets processing
locals {
  secrets_config = {
    for k, v in var.secrets : k => {
      name_prefix                    = lookup(v, "name_prefix", null)
      name                           = lookup(v, "name", null)
      description                    = lookup(v, "description", null)
      kms_key_id                     = lookup(v, "kms_key_id", null)
      # ... other configuration options
      computed_name = lookup(v, "name", null) != null ? lookup(v, "name", null) : (lookup(v, "name_prefix", null) != null ? null : k)
    }
  }
}

# Direct usage with for_each
resource "aws_secretsmanager_secret" "sm" {
  for_each = var.secrets
  
  name                           = local.secrets_config[each.key].computed_name
  name_prefix                    = local.secrets_config[each.key].computed_name_prefix
  description                    = local.secrets_config[each.key].description
  # ... additional configuration per secret
}
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
  
  kms_key_id = try(each.value.kms_key_id, null)
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

## MCP Server Configuration

### Available MCP Servers
This project is configured to use the following Model Context Protocol (MCP) servers for enhanced documentation access:

#### Terraform MCP Server
**Purpose**: Access up-to-date Terraform and AWS provider documentation
**Package**: `@modelcontextprotocol/server-terraform`

**Local Configuration** (`.mcp.json`):
```json
{
  "mcpServers": {
    "terraform": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-terraform@latest"]
    }
  }
}
```

**Usage Examples**:
- `Look up aws_secretsmanager_secret resource documentation`
- `Find the latest Secrets Manager rotation examples`
- `Search for AWS Secrets Manager Terraform modules`
- `Get documentation for aws_secretsmanager_secret_version resource`

#### Context7 MCP Server
**Purpose**: Access general library and framework documentation
**Package**: `@upstash/context7-mcp`

**Local Configuration** (`.mcp.json`):
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

**Usage Examples**:
- `Look up Go testing patterns for Terratest`
- `Find AWS CLI Secrets Manager commands documentation`
- `Get current Terraform best practices for sensitive data`
- `Search for GitHub Actions workflow patterns`

### GitHub Actions Integration
The MCP servers are automatically available in GitHub Actions through the claude.yml workflow configuration. Claude can access the same documentation in PRs and issues as available locally.

### Usage Tips
1. **Be Specific**: When requesting documentation, specify the exact resource or concept
2. **Version Awareness**: Both servers provide current, version-specific documentation
3. **Combine Sources**: Use Terraform MCP for Secrets Manager-specific docs, Context7 for general development patterns
4. **Local vs CI**: Same MCP servers work in both local development and GitHub Actions

### Example Workflows

**Secrets Manager Resource Development**:
```
@claude I need to add support for cross-region secret replication. Can you look up the latest aws_secretsmanager_secret_replica documentation and show me how to implement this feature?
```

**Testing Pattern Research**:
```
@claude Look up current Terratest patterns for testing Secrets Manager resources and help me add comprehensive tests for the secret rotation feature.
```

**Security Enhancement**:
```
@claude Research the latest Secrets Manager security best practices and help me implement enhanced encryption configurations in this module.
```

**Ephemeral Mode Development**:
```
@claude Look up the latest Terraform ephemeral resource patterns and help me improve the write-only secret handling in this module.
```