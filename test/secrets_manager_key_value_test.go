package test

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSecretsManagerKeyValue(t *testing.T) {
	t.Parallel()

	// Generate a random name for the test resources
	testName := fmt.Sprintf("terratest-sm-kv-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-east-1"

	// Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/key-value",
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
	assert.Contains(t, secretName, "kv-secret", "Secret name should contain kv-secret")

	// Verify secret ARN is valid
	assert.Contains(t, secretArn, "arn:aws:secretsmanager", "Secret ARN should be valid")
	assert.Contains(t, secretArn, awsRegion, "Secret ARN should contain region")

	// Test that we can retrieve the secret from AWS
	secretValue := aws.GetSecretValue(t, awsRegion, secretName)
	assert.NotEmpty(t, secretValue, "Secret value should not be empty")

	// Parse the JSON secret value
	var secretData map[string]interface{}
	err := json.Unmarshal([]byte(secretValue), &secretData)
	require.NoError(t, err, "Secret value should be valid JSON")

	// Verify the key-value pairs
	expectedKeys := []string{"username", "password", "database", "host"}
	for _, key := range expectedKeys {
		assert.Contains(t, secretData, key, fmt.Sprintf("Secret should contain key: %s", key))
	}

	assert.Equal(t, "testuser", secretData["username"], "Username should match expected value")
	assert.Equal(t, "testpassword", secretData["password"], "Password should match expected value")
	assert.Equal(t, "testdb", secretData["database"], "Database should match expected value")
	assert.Equal(t, "localhost", secretData["host"], "Host should match expected value")
}
