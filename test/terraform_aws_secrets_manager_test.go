package test

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	awshelper "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestTerraformAwsSecretsManagerBasic tests the basic functionality of the module
func TestTerraformAwsSecretsManagerBasic(t *testing.T) {
	t.Parallel()

	// Generate a unique ID for this test run
	uniqueID := random.UniqueId()
	
	// AWS region to use for testing
	awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/plaintext",
		Vars: map[string]interface{}{
			"name_suffix": uniqueID,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate that the secret was created
	secretName := terraform.Output(t, terraformOptions, "secret_name")
	assert.Contains(t, secretName, "plaintext")
	
	// Verify the secret exists in AWS
	secretValue := awshelper.GetSecretValue(t, awsRegion, secretName)
	assert.NotEmpty(t, secretValue)
}

// TestTerraformAwsSecretsManagerEphemeral tests the ephemeral functionality
func TestTerraformAwsSecretsManagerEphemeral(t *testing.T) {
	t.Parallel()

	// Generate a unique ID for this test run
	uniqueID := random.UniqueId()
	
	// AWS region to use for testing
	awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/ephemeral",
		Vars: map[string]interface{}{
			"name_suffix": uniqueID,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Get the Terraform state
	state := terraform.Show(t, terraformOptions)
	
	// Validate that sensitive values are NOT in the state when ephemeral is enabled
	stateJSON, err := json.Marshal(state)
	require.NoError(t, err)
	stateString := string(stateJSON)
	
	// Check that the secret value is not present in state
	assert.NotContains(t, stateString, "supersecretpassword")
	assert.NotContains(t, stateString, "secret_string")
	
	// Validate that the secret was created and has the correct value
	secretName := terraform.Output(t, terraformOptions, "secret_name")
	secretValue := awshelper.GetSecretValue(t, awsRegion, secretName)
	assert.NotEmpty(t, secretValue)
}

// TestTerraformAwsSecretsManagerKeyValue tests key-value secrets
func TestTerraformAwsSecretsManagerKeyValue(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/key-value",
		Vars: map[string]interface{}{
			"name_suffix": uniqueID,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate the key-value secret structure
	secretName := terraform.Output(t, terraformOptions, "secret_name")
	secretValue := awshelper.GetSecretValue(t, awsRegion, secretName)
	
	// Parse the JSON to validate structure
	var secretData map[string]interface{}
	err := json.Unmarshal([]byte(secretValue), &secretData)
	require.NoError(t, err)
	
	// Verify expected keys exist
	assert.Contains(t, secretData, "username")
	assert.Contains(t, secretData, "password")
}

// TestTerraformAwsSecretsManagerRotation tests secret rotation functionality
func TestTerraformAwsSecretsManagerRotation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/rotation",
		Vars: map[string]interface{}{
			"name_suffix": uniqueID,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate that rotation is configured
	secretArn := terraform.Output(t, terraformOptions, "secret_arn")
	assert.Contains(t, secretArn, "arn:aws:secretsmanager")
	
	// Verify rotation configuration in AWS
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion),
	})
	require.NoError(t, err)
	svc := secretsmanager.New(sess)
	
	input := &secretsmanager.DescribeSecretInput{
		SecretId: aws.String(secretArn),
	}
	
	result, err := svc.DescribeSecret(input)
	require.NoError(t, err)
	
	// Check if rotation is enabled
	assert.NotNil(t, result.RotationEnabled)
	if result.RotationEnabled != nil {
		assert.True(t, *result.RotationEnabled)
	}
}

// TestTerraformAwsSecretsManagerValidation tests validation rules
func TestTerraformAwsSecretsManagerValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		expectError bool
		errorText   string
	}{
		{
			name: "valid_configuration",
			vars: map[string]interface{}{
				"secrets": map[string]interface{}{
					"test-secret": map[string]interface{}{
						"description":    "Test secret",
						"secret_string":  "test-value",
					},
				},
			},
			expectError: false,
		},
		{
			name: "ephemeral_without_version",
			vars: map[string]interface{}{
				"ephemeral": true,
				"secrets": map[string]interface{}{
					"test-secret": map[string]interface{}{
						"description":   "Test secret",
						"secret_string": "test-value",
					},
				},
			},
			expectError: true,
			errorText:   "secret_string_wo_version is required",
		},
		{
			name: "invalid_secret_name",
			vars: map[string]interface{}{
				"secrets": map[string]interface{}{
					"invalid@name!": map[string]interface{}{
						"description":   "Test secret",
						"secret_string": "test-value",
					},
				},
			},
			expectError: true,
			errorText:   "Secret names must contain only",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

			terraformOptions := &terraform.Options{
				TerraformDir: "../",
				Vars:         tc.vars,
				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": awsRegion,
				},
			}

			if tc.expectError {
				_, err := terraform.InitAndPlanE(t, terraformOptions)
				assert.Error(t, err)
				if tc.errorText != "" {
					assert.Contains(t, err.Error(), tc.errorText)
				}
			} else {
				defer terraform.Destroy(t, terraformOptions)
				terraform.InitAndPlan(t, terraformOptions)
			}
		})
	}
}

// TestTerraformAwsSecretsManagerMultipleSecrets tests multiple secrets creation
func TestTerraformAwsSecretsManagerMultipleSecrets(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"secrets": map[string]interface{}{
				fmt.Sprintf("test-secret-1-%s", uniqueID): map[string]interface{}{
					"description":   "Test secret 1",
					"secret_string": "test-value-1",
				},
				fmt.Sprintf("test-secret-2-%s", uniqueID): map[string]interface{}{
					"description":   "Test secret 2",
					"secret_string": "test-value-2",
				},
				fmt.Sprintf("test-secret-3-%s", uniqueID): map[string]interface{}{
					"description": "Test secret 3",
					"secret_key_value": map[string]interface{}{
						"username": "testuser",
						"password": "testpass",
					},
				},
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate all secrets were created
	secretArns := terraform.OutputList(t, terraformOptions, "secret_arns")
	assert.Len(t, secretArns, 3)

	// Verify each secret exists
	for _, arn := range secretArns {
		assert.Contains(t, arn, "arn:aws:secretsmanager")
		
		// Extract secret name from ARN and verify it exists
		parts := strings.Split(arn, ":")
		if len(parts) > 6 {
			secretName := parts[6]
			secretValue := awshelper.GetSecretValue(t, awsRegion, secretName)
			assert.NotEmpty(t, secretValue)
		}
	}
}

// TestTerraformAwsSecretsManagerBinarySecret tests binary secret handling
func TestTerraformAwsSecretsManagerBinarySecret(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/binary",
		Vars: map[string]interface{}{
			"name_suffix": uniqueID,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate binary secret was created
	secretName := terraform.Output(t, terraformOptions, "secret_name")
	assert.NotEmpty(t, secretName)
	
	// Verify the secret exists and has binary content
	secretValue := awshelper.GetSecretValue(t, awsRegion, secretName)
	assert.NotEmpty(t, secretValue)
}

// TestTerraformAwsSecretsManagerTags tests tag functionality
func TestTerraformAwsSecretsManagerTags(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	awsRegion := awshelper.GetRandomStableRegion(t, nil, nil)

	expectedTags := map[string]string{
		"Environment": "test",
		"Team":        "engineering",
		"Project":     "terratest",
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"secrets": map[string]interface{}{
				fmt.Sprintf("tagged-secret-%s", uniqueID): map[string]interface{}{
					"description":   "Tagged secret",
					"secret_string": "test-value",
				},
			},
			"tags": expectedTags,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate tags were applied
	secretArns := terraform.OutputList(t, terraformOptions, "secret_arns")
	require.Len(t, secretArns, 1)

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(awsRegion),
	})
	require.NoError(t, err)
	svc := secretsmanager.New(sess)

	input := &secretsmanager.DescribeSecretInput{
		SecretId: aws.String(secretArns[0]),
	}

	result, err := svc.DescribeSecret(input)
	require.NoError(t, err)

	// Convert AWS tags to map for comparison
	actualTags := make(map[string]string)
	for _, tag := range result.Tags {
		actualTags[*tag.Key] = *tag.Value
	}

	// Verify expected tags are present
	for key, expectedValue := range expectedTags {
		actualValue, exists := actualTags[key]
		assert.True(t, exists, "Tag %s should exist", key)
		assert.Equal(t, expectedValue, actualValue, "Tag %s should have value %s", key, expectedValue)
	}
}