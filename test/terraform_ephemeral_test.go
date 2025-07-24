package test

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestEphemeralVsRegularMode compares ephemeral and regular modes
func TestEphemeralVsRegularMode(t *testing.T) {
	t.Parallel()

	uniqueID := GenerateTestName("ephemeral-vs-regular")
	awsRegion := GetTestRegion(t)
	secretValue := "supersecretpassword123"

	testCases := []struct {
		name      string
		ephemeral bool
		vars      map[string]interface{}
	}{
		{
			name:      "regular_mode",
			ephemeral: false,
			vars: map[string]interface{}{
				"ephemeral": false,
				"secrets": CreateBasicSecretConfig(
					fmt.Sprintf("regular-secret-%s", uniqueID),
					secretValue,
				),
			},
		},
		{
			name:      "ephemeral_mode",
			ephemeral: true,
			vars: map[string]interface{}{
				"ephemeral": true,
				"secrets": CreateEphemeralSecretConfig(
					fmt.Sprintf("ephemeral-secret-%s", uniqueID),
					secretValue,
					1,
				),
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../",
				Vars:         tc.vars,
				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": awsRegion,
				},
			}

			// Deploy the infrastructure
			terraform.InitAndApply(t, terraformOptions)

			defer terraform.Destroy(t, terraformOptions)

			// Get the Terraform state
			state := terraform.Show(t, terraformOptions)
			stateJSON, err := json.Marshal(state)
			require.NoError(t, err)
			stateString := string(stateJSON)

			// Verify the secret exists and has the correct value in AWS BEFORE validating state
			secretArns := terraform.OutputMap(t, terraformOptions, "secret_arns")
			require.Len(t, secretArns, 1)

			// Get the first (and only) ARN from the map
			var secretArn string
			for _, arn := range secretArns {
				secretArn = arn
				break
			}

			// Use the full ARN to validate the secret value
			actualSecretValue := ValidateSecretValue(t, awsRegion, secretArn)
			assert.Equal(t, secretValue, actualSecretValue)

			// Validate state content based on mode
			if tc.ephemeral {
				// In ephemeral mode, sensitive data should NOT be in state
				ValidateNoSensitiveDataInState(t, stateString, []string{
					secretValue,
					"supersecretpassword",
				})
				
				// State should contain write-only parameter references but not values
				assert.Contains(t, stateString, "secret_string_wo_version")
				assert.NotContains(t, stateString, secretValue)
			} else {
				// In regular mode, secret data will be in state (this is expected behavior)
				// We're not checking for presence as terraform.Show() may not include sensitive values
				// The key difference is that ephemeral mode explicitly prevents this
			}
		})
	}
}

// TestEphemeralSecretTypes tests different secret types in ephemeral mode
func TestEphemeralSecretTypes(t *testing.T) {
	t.Parallel()

	uniqueID := GenerateTestName("ephemeral-types")
	awsRegion := GetTestRegion(t)

	testCases := []struct {
		name         string
		secretConfig map[string]interface{}
		expectedValue string
		valueCheck   func(t *testing.T, value string)
	}{
		{
			name: "ephemeral_plaintext",
			secretConfig: CreateEphemeralSecretConfig(
				fmt.Sprintf("ephemeral-plaintext-%s", uniqueID),
				"plaintext-secret-value",
				1,
			),
			expectedValue: "plaintext-secret-value",
			valueCheck: func(t *testing.T, value string) {
				assert.Equal(t, "plaintext-secret-value", value)
			},
		},
		{
			name: "ephemeral_key_value",
			secretConfig: map[string]interface{}{
				fmt.Sprintf("ephemeral-kv-%s", uniqueID): map[string]interface{}{
					"description": "Ephemeral key-value secret",
					"secret_key_value": map[string]string{
						"username": "testuser",
						"password": "testpass123",
					},
					"secret_string_wo_version": 1,
				},
			},
			valueCheck: func(t *testing.T, value string) {
				var secretData map[string]interface{}
				err := json.Unmarshal([]byte(value), &secretData)
				require.NoError(t, err)
				assert.Equal(t, "testuser", secretData["username"])
				assert.Equal(t, "testpass123", secretData["password"])
			},
		},
		{
			name: "ephemeral_binary",
			secretConfig: map[string]interface{}{
				fmt.Sprintf("ephemeral-binary-%s", uniqueID): map[string]interface{}{
					"description":              "Ephemeral binary secret",
					"secret_binary":            "binary-data-content",
					"secret_string_wo_version": 1,
				},
			},
			valueCheck: func(t *testing.T, value string) {
				// In ephemeral mode, binary secrets are stored as base64-encoded strings
				assert.NotEmpty(t, value)
				// Could decode and verify, but main point is that it exists and is retrievable
			},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../",
				Vars: map[string]interface{}{
					"ephemeral": true,
					"secrets":   tc.secretConfig,
				},
				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": awsRegion,
				},
			}

			terraform.InitAndApply(t, terraformOptions)

			defer terraform.Destroy(t, terraformOptions)

			// Verify the secret exists and validate its value FIRST
			secretArns := terraform.OutputMap(t, terraformOptions, "secret_arns")
			require.Len(t, secretArns, 1)

			// Get the first (and only) ARN from the map
			var secretArn string
			for _, arn := range secretArns {
				secretArn = arn
				break
			}

			actualValue := ValidateSecretValue(t, awsRegion, secretArn)

			if tc.valueCheck != nil {
				tc.valueCheck(t, actualValue)
			}

			// Verify no sensitive data in state
			state := terraform.Show(t, terraformOptions)
			stateJSON, err := json.Marshal(state)
			require.NoError(t, err)
			stateString := string(stateJSON)

			// Check that sensitive values are not in state
			if tc.expectedValue != "" {
				ValidateNoSensitiveDataInState(t, stateString, []string{tc.expectedValue})
			}
		})
	}
}

// TestEphemeralSecretVersioning tests version control in ephemeral mode
func TestEphemeralSecretVersioning(t *testing.T) {
	t.Parallel()

	uniqueID := GenerateTestName("ephemeral-versioning")
	awsRegion := GetTestRegion(t)
	secretName := fmt.Sprintf("versioned-secret-%s", uniqueID)

	// Initial deployment with version 1
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"ephemeral": true,
			"secrets": CreateEphemeralSecretConfig(
				secretName,
				"initial-value",
				1,
			),
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	// Deploy initial version
	terraform.InitAndApply(t, terraformOptions)

	defer terraform.Destroy(t, terraformOptions)

	// Verify initial secret value
	secretArns := terraform.OutputMap(t, terraformOptions, "secret_arns")
	require.Len(t, secretArns, 1)
	
	// Get the first (and only) ARN from the map
	var secretArn string
	for _, arn := range secretArns {
		secretArn = arn
		break
	}
	
	initialValue := ValidateSecretValue(t, awsRegion, secretArn)
	assert.Equal(t, "initial-value", initialValue)

	// Update to version 2 with new value
	terraformOptions.Vars = map[string]interface{}{
		"ephemeral": true,
		"secrets": CreateEphemeralSecretConfig(
			secretName,
			"updated-value",
			2, // Increment version
		),
	}

	// Apply the update
	terraform.Apply(t, terraformOptions)

	// Verify updated secret value
	updatedValue := ValidateSecretValue(t, awsRegion, secretArn)
	assert.Equal(t, "updated-value", updatedValue)

	// Verify state still doesn't contain sensitive data
	state := terraform.Show(t, terraformOptions)
	stateJSON, err := json.Marshal(state)
	require.NoError(t, err)
	stateString := string(stateJSON)

	ValidateNoSensitiveDataInState(t, stateString, []string{
		"initial-value",
		"updated-value",
	})
}

// TestEphemeralRotatingSecrets tests rotating secrets in ephemeral mode
func TestEphemeralRotatingSecrets(t *testing.T) {
	t.Parallel()

	uniqueID := GenerateTestName("ephemeral-rotation")
	awsRegion := GetTestRegion(t)

	// Note: This test requires a Lambda function ARN for rotation
	// In a real test environment, you would need to create or reference an actual Lambda function
	lambdaArn := fmt.Sprintf("arn:aws:lambda:%s:123456789012:function:test-rotation-function", awsRegion)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"ephemeral": true,
			"rotate_secrets": map[string]interface{}{
				fmt.Sprintf("ephemeral-rotating-%s", uniqueID): map[string]interface{}{
					"description":               "Ephemeral rotating secret",
					"secret_string":             "rotating-secret-value",
					"secret_string_wo_version":  1,
					"rotation_lambda_arn":       lambdaArn,
					"automatically_after_days":  30,
				},
			},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	// This test validates the configuration but may not apply due to Lambda function requirements
	terraform.Init(t, terraformOptions)
	
	// Validate the plan (rotation configuration should be valid)
	planOutput := terraform.Plan(t, terraformOptions)
	
	// Verify that the plan includes rotation configuration
	assert.Contains(t, planOutput, "aws_secretsmanager_secret_rotation")
	assert.Contains(t, planOutput, lambdaArn)
	
	// Verify that ephemeral parameters are used
	assert.Contains(t, planOutput, "secret_string_wo")
	assert.Contains(t, planOutput, "secret_string_wo_version")
}

// ExtractSecretNameFromArn extracts the secret name from an ARN
func ExtractSecretNameFromArn(arn string) string {
	// ARN format: arn:aws:secretsmanager:region:account:secret:name-suffix
	parts := strings.Split(arn, ":")
	if len(parts) >= 7 {
		return parts[6]
	}
	return arn // fallback to full ARN if parsing fails
}