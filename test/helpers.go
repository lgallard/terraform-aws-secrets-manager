package test

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	awstest "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/stretchr/testify/require"
)

// TestCase represents a test case for the secrets manager module
type TestCase struct {
	Name        string
	Description string
	Vars        map[string]interface{}
	ExpectError bool
	ErrorText   string
}

// GenerateTestName creates a unique test name with prefix
func GenerateTestName(prefix string) string {
	return fmt.Sprintf("%s-%s", prefix, strings.ToLower(random.UniqueId()))
}

// GetTestRegion returns a stable AWS region for testing
func GetTestRegion(t *testing.T) string {
	return awstest.GetRandomStableRegion(t, nil, nil)
}

// WaitForSecretDeletion waits for a secret to be completely deleted from AWS
func WaitForSecretDeletion(t *testing.T, region, secretName string, maxRetries int, sleepBetweenRetries time.Duration) {
	retry.DoWithRetry(t, fmt.Sprintf("Waiting for secret %s to be deleted", secretName), maxRetries, sleepBetweenRetries, func() (string, error) {
		sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	require.NoError(t, err)
		svc := secretsmanager.New(sess)

		_, errDesc := svc.DescribeSecret(&secretsmanager.DescribeSecretInput{
			SecretId: aws.String(secretName),
		})

		if errDesc != nil {
			// If the secret is not found, it means it's been deleted
			if strings.Contains(errDesc.Error(), "ResourceNotFoundException") {
				return "Secret deleted successfully", nil
			}
			return "", errDesc
		}

		return "", fmt.Errorf("Secret %s still exists", secretName)
	})
}

// ValidateSecretExists checks if a secret exists in AWS Secrets Manager
func ValidateSecretExists(t *testing.T, region, secretName string) *secretsmanager.DescribeSecretOutput {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	require.NoError(t, err)
	svc := secretsmanager.New(sess)

	input := &secretsmanager.DescribeSecretInput{
		SecretId: aws.String(secretName),
	}

	result, err := svc.DescribeSecret(input)
	require.NoError(t, err, "Failed to describe secret %s", secretName)
	
	return result
}

// ValidateSecretValue retrieves and validates a secret value
func ValidateSecretValue(t *testing.T, region, secretName string) string {
	secretValue := awstest.GetSecretValue(t, region, secretName)
	require.NotEmpty(t, secretValue, "Secret value should not be empty")
	return secretValue
}

// ValidateSecretTags checks if expected tags are present on a secret
func ValidateSecretTags(t *testing.T, region, secretName string, expectedTags map[string]string) {
	secretInfo := ValidateSecretExists(t, region, secretName)
	
	actualTags := make(map[string]string)
	for _, tag := range secretInfo.Tags {
		actualTags[*tag.Key] = *tag.Value
	}

	for key, expectedValue := range expectedTags {
		actualValue, exists := actualTags[key]
		require.True(t, exists, "Tag %s should exist", key)
		require.Equal(t, expectedValue, actualValue, "Tag %s should have value %s", key, expectedValue)
	}
}

// ValidateRotationConfiguration checks rotation settings for a secret
func ValidateRotationConfiguration(t *testing.T, region, secretName string, expectedRotationEnabled bool) {
	secretInfo := ValidateSecretExists(t, region, secretName)
	
	if expectedRotationEnabled {
		require.NotNil(t, secretInfo.RotationEnabled, "RotationEnabled should not be nil")
		require.True(t, *secretInfo.RotationEnabled, "Rotation should be enabled")
		require.NotNil(t, secretInfo.RotationLambdaARN, "RotationLambdaARN should not be nil when rotation is enabled")
	} else {
		if secretInfo.RotationEnabled != nil {
			require.False(t, *secretInfo.RotationEnabled, "Rotation should be disabled")
		}
	}
}

// CleanupTestSecrets removes test secrets that might be left over
func CleanupTestSecrets(t *testing.T, region string, namePrefix string) {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	require.NoError(t, err)
	svc := secretsmanager.New(sess)

	// List all secrets
	input := &secretsmanager.ListSecretsInput{}
	result, err := svc.ListSecrets(input)
	if err != nil {
		t.Logf("Warning: Failed to list secrets for cleanup: %v", err)
		return
	}

	// Delete secrets that match the test prefix
	for _, secret := range result.SecretList {
		if secret.Name != nil && strings.HasPrefix(*secret.Name, namePrefix) {
			t.Logf("Cleaning up test secret: %s", *secret.Name)
			
			_, err := svc.DeleteSecret(&secretsmanager.DeleteSecretInput{
				SecretId:                   secret.Name,
				ForceDeleteWithoutRecovery: aws.Bool(true),
			})
			
			if err != nil {
				t.Logf("Warning: Failed to delete test secret %s: %v", *secret.Name, err)
			}
		}
	}
}

// GetCommonTestVars returns common variables used across tests
func GetCommonTestVars(uniqueID string) map[string]interface{} {
	return map[string]interface{}{
		"name_suffix": uniqueID,
		"tags": map[string]string{
			"Environment": "test",
			"ManagedBy":   "terratest",
			"TestRun":     uniqueID,
		},
	}
}

// ValidateNoSensitiveDataInState checks that sensitive data is not present in Terraform state
func ValidateNoSensitiveDataInState(t *testing.T, stateContent string, sensitiveValues []string) {
	for _, sensitiveValue := range sensitiveValues {
		require.NotContains(t, stateContent, sensitiveValue, 
			"Sensitive value '%s' should not be present in Terraform state", sensitiveValue)
	}
}

// CreateBasicSecretConfig creates a basic secret configuration for testing
func CreateBasicSecretConfig(secretName, secretValue string) map[string]interface{} {
	return map[string]interface{}{
		secretName: map[string]interface{}{
			"description":   fmt.Sprintf("Test secret: %s", secretName),
			"secret_string": secretValue,
		},
	}
}

// CreateEphemeralSecretConfig creates an ephemeral secret configuration for testing
func CreateEphemeralSecretConfig(secretName, secretValue string, version int) map[string]interface{} {
	return map[string]interface{}{
		secretName: map[string]interface{}{
			"description":               fmt.Sprintf("Ephemeral test secret: %s", secretName),
			"secret_string":             secretValue,
			"secret_string_wo_version":  version,
		},
	}
}

// CreateKeyValueSecretConfig creates a key-value secret configuration for testing
func CreateKeyValueSecretConfig(secretName string, keyValues map[string]string) map[string]interface{} {
	return map[string]interface{}{
		secretName: map[string]interface{}{
			"description":      fmt.Sprintf("Key-value test secret: %s", secretName),
			"secret_key_value": keyValues,
		},
	}
}

// CreateRotatingSecretConfig creates a rotating secret configuration for testing
func CreateRotatingSecretConfig(secretName, secretValue, lambdaArn string) map[string]interface{} {
	return map[string]interface{}{
		secretName: map[string]interface{}{
			"description":          fmt.Sprintf("Rotating test secret: %s", secretName),
			"secret_string":        secretValue,
			"rotation_lambda_arn":  lambdaArn,
			"automatically_after_days": 30,
		},
	}
}