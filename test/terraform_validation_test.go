package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformFormat tests that all Terraform files are properly formatted
func TestTerraformFormat(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	// Run terraform fmt -check to see if files are formatted correctly
	output, err := terraform.RunTerraformCommandAndGetStdoutE(t, terraformOptions, "fmt", "-check", "-diff")
	
	if err != nil {
		t.Errorf("Terraform files are not properly formatted. Run 'terraform fmt' to fix.\nOutput: %s", output)
	}
}

// TestTerraformValidate tests that the Terraform configuration is valid
func TestTerraformValidate(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	// Initialize and validate
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestExamplesValidation tests that all example configurations are valid
func TestExamplesValidation(t *testing.T) {
	testCases := []struct {
		name string
		path string
	}{
		{"plaintext", "../examples/plaintext"},
		{"key-value", "../examples/key-value"},
		{"binary", "../examples/binary"},
		{"ephemeral", "../examples/ephemeral"},
		{"rotation", "../examples/rotation"},
		{"replication", "../examples/replication"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: tc.path,
			}

			// Initialize and validate each example
			terraform.Init(t, terraformOptions)
			terraform.Validate(t, terraformOptions)
		})
	}
}

// TestTerraformPlan tests that terraform plan runs without errors
func TestTerraformPlan(t *testing.T) {
	t.Parallel()

	uniqueID := GenerateTestName("plan-test")
	awsRegion := GetTestRegion(t)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"secrets": CreateBasicSecretConfig(
				fmt.Sprintf("test-secret-%s", uniqueID),
				"test-value",
			),
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	// Test that plan runs successfully
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)
	
	// Basic validation that plan contains expected resources
	assert.Contains(t, planOutput, "aws_secretsmanager_secret")
	assert.Contains(t, planOutput, "aws_secretsmanager_secret_version")
}

// TestVariableValidation tests input variable validation
func TestVariableValidation(t *testing.T) {
	testCases := []ValidationTestCase{
		{
			Name: "valid_basic_secret",
			Vars: map[string]interface{}{
				"secrets": CreateBasicSecretConfig("valid-secret", "test-value"),
			},
			ExpectError: false,
		},
		{
			Name: "invalid_secret_name_special_chars",
			Vars: map[string]interface{}{
				"secrets": CreateBasicSecretConfig("invalid@secret!", "test-value"),
			},
			ExpectError: true,
			ErrorText:   "Secret names must contain only",
		},
		{
			Name: "ephemeral_missing_version",
			Vars: map[string]interface{}{
				"ephemeral": true,
				"secrets":   CreateBasicSecretConfig("ephemeral-secret", "test-value"),
			},
			ExpectError: true,
			ErrorText:   "secret_string_wo_version is required",
		},
		{
			Name: "ephemeral_with_valid_version",
			Vars: map[string]interface{}{
				"ephemeral": true,
				"secrets":   CreateEphemeralSecretConfig("ephemeral-secret", "test-value", 1),
			},
			ExpectError: false,
		},
		{
			Name: "invalid_kms_key_format",
			Vars: map[string]interface{}{
				"secrets": map[string]interface{}{
					"test-secret": map[string]interface{}{
						"description":   "Test secret",
						"secret_string": "test-value",
						"kms_key_id":    "invalid-kms-key",
					},
				},
			},
			ExpectError: true,
			ErrorText:   "KMS key ID must be a valid",
		},
		{
			Name: "valid_kms_key_arn",
			Vars: map[string]interface{}{
				"secrets": map[string]interface{}{
					"test-secret": map[string]interface{}{
						"description":   "Test secret",
						"secret_string": "test-value",
						"kms_key_id":    "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
					},
				},
			},
			ExpectError: false,
		},
		{
			Name: "invalid_tag_key_aws_prefix",
			Vars: map[string]interface{}{
				"secrets": CreateBasicSecretConfig("test-secret", "test-value"),
				"tags": map[string]string{
					"aws:test": "value",
				},
			},
			ExpectError: true,
			ErrorText:   "Tag keys cannot start with 'aws:'",
		},
		{
			Name: "invalid_recovery_window",
			Vars: map[string]interface{}{
				"secrets":                  CreateBasicSecretConfig("test-secret", "test-value"),
				"recovery_window_in_days": 5, // Invalid: must be 0 or between 7-30
			},
			ExpectError: true,
			ErrorText:   "Recovery window must be 0",
		},
		{
			Name: "rotation_missing_lambda",
			Vars: map[string]interface{}{
				"rotate_secrets": map[string]interface{}{
					"rotating-secret": map[string]interface{}{
						"description":   "Rotating secret",
						"secret_string": "test-value",
						// Missing rotation_lambda_arn
					},
				},
			},
			ExpectError: true,
			ErrorText:   "rotation_lambda_arn",
		},
		{
			Name: "both_secret_string_and_binary",
			Vars: map[string]interface{}{
				"secrets": map[string]interface{}{
					"conflict-secret": map[string]interface{}{
						"description":    "Conflict secret",
						"secret_string":  "test-value",
						"secret_binary":  "binary-data",
					},
				},
			},
			ExpectError: true,
			ErrorText:   "Cannot specify both secret_string and secret_binary",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.Name, func(t *testing.T) {
			awsRegion := GetTestRegion(t)

			terraformOptions := &terraform.Options{
				TerraformDir: "../",
				Vars:         tc.Vars,
				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": awsRegion,
				},
			}

			// Initialize
			terraform.Init(t, terraformOptions)

			// Test validation
			if tc.ExpectError {
				_, err := terraform.PlanE(t, terraformOptions)
				assert.Error(t, err, "Expected validation error for test case: %s", tc.Name)
				if tc.ErrorText != "" {
					assert.Contains(t, err.Error(), tc.ErrorText, 
						"Error message should contain expected text for test case: %s", tc.Name)
				}
			} else {
				// Should not error
				terraform.Plan(t, terraformOptions)
			}
		})
	}
}

// ValidationTestCase represents a test case for validation testing
type ValidationTestCase struct {
	Name        string
	Vars        map[string]interface{}
	ExpectError bool
	ErrorText   string
}