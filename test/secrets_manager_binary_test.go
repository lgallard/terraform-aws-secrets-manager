package test

import (
	"encoding/base64"
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSecretsManagerBinary(t *testing.T) {
	t.Parallel()

	// Generate a random name for the test resources
	testName := fmt.Sprintf("terratest-sm-bin-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-east-1"

	// Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/binary",
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
	secretArn := terraform.Output(t, terraformOptions, "secret_arn")
	secretName := terraform.Output(t, terraformOptions, "secret_name")
	secretId := terraform.Output(t, terraformOptions, "secret_id")

	// Verify outputs are not empty
	assert.NotEmpty(t, secretArn, "Secret ARN should not be empty")
	assert.NotEmpty(t, secretName, "Secret name should not be empty")
	assert.NotEmpty(t, secretId, "Secret ID should not be empty")

	// Verify secret name contains our test prefix
	assert.Contains(t, secretName, testName, "Secret name should contain test prefix")
	assert.Contains(t, secretName, "binary-secret", "Secret name should contain binary-secret")

	// Verify secret ARN is valid
	assert.Contains(t, secretArn, "arn:aws:secretsmanager", "Secret ARN should be valid")
	assert.Contains(t, secretArn, awsRegion, "Secret ARN should contain region")

	// Test that we can retrieve the secret from AWS
	// For binary secrets, AWS returns the value base64 decoded
	secretValue := aws.GetSecretValue(t, awsRegion, secretName)
	assert.NotEmpty(t, secretValue, "Secret value should not be empty")

	// The original binary data was base64 encoded by the module, so AWS stores it as binary
	// and returns it as a string. We should verify it contains the SSH key content
	assert.Contains(t, secretValue, "ssh-rsa", "Secret should contain SSH key")
	assert.Contains(t, secretValue, "test@example.com", "Secret should contain email")
}

func TestSecretsManagerBinaryEncoding(t *testing.T) {
	// Test that our binary encoding works correctly
	originalData := "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDt4TcI58h4G0wR+GcDY+0VJR10JNvG92jEKGaKxeMaOkfsXflVGsYXbfVBBCG/n3uHtTse7baYLB6LWQAuYWL1SHJVhhTQ7pPiocFWibAvJlVo1l7qJEDu2OxKpWEleCE+p3ufNXAy7v5UFO7EOnj0Zg6R3F/MiAWbQnaEHcYzNtogyC24YBecBLrBXZNi1g0AN1hM9k+3XvWUYTf9vPv8LIWnqo7y4Q2iEGWWurf37YFl1LzX4mG/Co+Vfe5TlZSe2YPMYWlw0ZKaK test@example.com"

	// Encode to base64 (simulating what the module does)
	encoded := base64.StdEncoding.EncodeToString([]byte(originalData))
	assert.NotEmpty(t, encoded, "Encoded data should not be empty")

	// Decode back
	decoded, err := base64.StdEncoding.DecodeString(encoded)
	require.NoError(t, err, "Should be able to decode base64")

	// Verify round trip
	assert.Equal(t, originalData, string(decoded), "Decoded data should match original")
}
