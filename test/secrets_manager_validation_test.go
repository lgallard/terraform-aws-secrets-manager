package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSecretsManagerValidation(t *testing.T) {
	t.Parallel()

	// Generate a random name for the test resources
	testName := fmt.Sprintf("terratest-sm-val-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-east-1"

	// Test valid recovery window
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/validation",
		Vars: map[string]interface{}{
			"test_name":       testName,
			"aws_region":      awsRegion,
			"recovery_window": 7,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply" to deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Get the outputs
	secretArn := terraform.Output(t, terraformOptions, "secret_arn")
	secretName := terraform.Output(t, terraformOptions, "secret_name")

	// Verify outputs are not empty
	assert.NotEmpty(t, secretArn, "Secret ARN should not be empty")
	assert.NotEmpty(t, secretName, "Secret name should not be empty")

	// Verify secret name contains our test prefix
	assert.Contains(t, secretName, testName, "Secret name should contain test prefix")
	assert.Contains(t, secretName, "validation-secret", "Secret name should contain validation-secret")
}

func TestSecretsManagerValidationInvalidRecoveryWindow(t *testing.T) {
	t.Parallel()

	// Generate a random name for the test resources
	testName := fmt.Sprintf("terratest-sm-val-invalid-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-east-1"

	// Test invalid recovery window (should fail)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/validation",
		Vars: map[string]interface{}{
			"test_name":       testName,
			"aws_region":      awsRegion,
			"recovery_window": 5, // Invalid: should be 0 or 7-30
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// This should fail during plan/apply
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err, "Should fail with invalid recovery window")
	assert.Contains(t, err.Error(), "Recovery window must be 0", "Error should mention recovery window validation")
}

func TestSecretsManagerValidationBoundaryValues(t *testing.T) {
	// Test boundary values for recovery window
	testCases := []struct {
		name           string
		recoveryWindow int
		shouldPass     bool
	}{
		{"Zero recovery window", 0, true},
		{"Minimum valid recovery window", 7, true},
		{"Maximum valid recovery window", 30, true},
		{"Below minimum", 6, false},
		{"Above maximum", 31, false},
		{"Negative value", -1, false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Generate a random name for the test resources
			testName := fmt.Sprintf("terratest-sm-boundary-%s", strings.ToLower(random.UniqueId()))
			awsRegion := "us-east-1"

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "./fixtures/validation",
				Vars: map[string]interface{}{
					"test_name":       testName,
					"aws_region":      awsRegion,
					"recovery_window": tc.recoveryWindow,
				},
				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": awsRegion,
				},
			})

			if tc.shouldPass {
				// Clean up resources with "terraform destroy" at the end of the test
				defer terraform.Destroy(t, terraformOptions)

				// This should succeed
				terraform.InitAndApply(t, terraformOptions)

				// Get the outputs
				secretArn := terraform.Output(t, terraformOptions, "secret_arn")
				assert.NotEmpty(t, secretArn, "Secret ARN should not be empty")
			} else {
				// This should fail during plan/apply
				_, err := terraform.InitAndPlanE(t, terraformOptions)
				assert.Error(t, err, "Should fail with invalid recovery window: %d", tc.recoveryWindow)
			}
		})
	}
}
