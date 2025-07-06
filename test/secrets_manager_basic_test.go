package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSecretsManagerBasic(t *testing.T) {
	t.Parallel()

	// Generate a random name for the test resources
	testName := fmt.Sprintf("terratest-sm-basic-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-east-1"

	// Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/basic",
		Vars: map[string]interface{}{
			"test_name":  testName,
			"aws_region": awsRegion,
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
	secretArns := terraform.OutputList(t, terraformOptions, "secret_arns")
	secretNames := terraform.OutputList(t, terraformOptions, "secret_names")
	secretIds := terraform.OutputList(t, terraformOptions, "secret_ids")

	// Verify we have the expected number of secrets
	assert.Len(t, secretArns, 2, "Should have 2 secret ARNs")
	assert.Len(t, secretNames, 2, "Should have 2 secret names")
	assert.Len(t, secretIds, 2, "Should have 2 secret IDs")

	// Verify secret names contain our test prefix
	for _, name := range secretNames {
		assert.Contains(t, name, testName, "Secret name should contain test prefix")
	}

	// Verify secret ARNs are valid
	for _, arn := range secretArns {
		assert.Contains(t, arn, "arn:aws:secretsmanager", "Secret ARN should be valid")
		assert.Contains(t, arn, awsRegion, "Secret ARN should contain region")
	}

	// Test that we can retrieve the secrets from AWS
	for i, secretName := range secretNames {
		// Get secret value
		secretValue := aws.GetSecretValue(t, awsRegion, secretName)
		assert.NotEmpty(t, secretValue, "Secret value should not be empty")

		// Verify the secret value matches what we expect
		expectedValue := fmt.Sprintf("test-value-%d", i+1)
		assert.Equal(t, expectedValue, secretValue, "Secret value should match expected value")
	}
}
