package main

import (
	"log"
	"os"
	"regexp"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
)

func main() {
	region := os.Getenv("AWS_DEFAULT_REGION")
	if region == "" {
		region = "us-east-1"
	}

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		log.Fatalf("Failed to create AWS session: %v", err)
	}

	svc := secretsmanager.New(sess)

	// Define test prefixes to clean up
	testPrefixes := []string{
		"plan-test-",
		"ephemeral-vs-regular-",
		"ephemeral-types-",
		"ephemeral-versioning-",
		"ephemeral-rotation-",
		"test-secret-",
		"ephemeral-secret-",
		"tagged-secret-",
		"regular-secret-",
		"ephemeral-plaintext-",
		"ephemeral-kv-",
		"ephemeral-binary-",
		"versioned-secret-",
		"ephemeral-rotating-",
		// Additional patterns found in tests
		"plaintext-", 
		"keyvalue-",
		"rotation-",
		"binary-",
		"multiple-secrets-",
		"basic-",
		"complete-",
		"example-",
	}

	log.Printf("Starting cleanup of test secrets in region %s", region)

	// List all secrets with pagination support
	var allSecrets []*secretsmanager.SecretListEntry
	input := &secretsmanager.ListSecretsInput{}
	
	for {
		result, err := svc.ListSecrets(input)
		if err != nil {
			log.Fatalf("Failed to list secrets: %v", err)
		}
		
		allSecrets = append(allSecrets, result.SecretList...)
		
		// Check if there are more results
		if result.NextToken == nil {
			break
		}
		input.NextToken = result.NextToken
	}

	log.Printf("Found %d total secrets to evaluate", len(allSecrets))
	deletedCount := 0
	for _, secret := range allSecrets {
		if secret.Name == nil {
			continue
		}

		secretName := *secret.Name
		shouldDelete := false

		// Check if secret matches any test prefix
		for _, prefix := range testPrefixes {
			if strings.HasPrefix(secretName, prefix) {
				shouldDelete = true
				break
			}
		}

		// Also check for secrets created in the last 6 hours with test-like patterns
		// This catches test secrets that may not match exact prefixes
		if !shouldDelete && secret.CreatedDate != nil {
			timeSinceCreation := time.Since(*secret.CreatedDate)
			if timeSinceCreation < 6*time.Hour {
				// Check for common test patterns (more aggressive)
				testPatterns := []string{
					"test-",
					"terratest-",
					"ephemeral-",
					"validation-",
					// UUID patterns that indicate test names
					"-abcdef", "-123456", "-test", "-demo",
					// Common Terratest random ID patterns
					"-random-", "-unique-",
				}
				secretNameLower := strings.ToLower(secretName)
				for _, pattern := range testPatterns {
					if strings.Contains(secretNameLower, pattern) {
						shouldDelete = true
						break
					}
				}
				
				// Add time bounds validation to prevent negative durations or clock skew issues  
				if !shouldDelete && timeSinceCreation >= 0 && timeSinceCreation < 6*time.Hour {
					// Check for names with random suffix patterns (like Terratest generates)
					if len(secretName) > 10 && strings.Contains(secretName, "-") {
						parts := strings.Split(secretName, "-")
						for _, part := range parts {
							// Look for hex patterns or purely numeric patterns that indicate test IDs
							if len(part) >= 6 && (isHexString(part) || isNumericString(part)) {
								shouldDelete = true
								break
							}
						}
					}
				}
			}
		}

		if shouldDelete {
			log.Printf("Deleting test secret: %s", secretName)
			
			_, err := svc.DeleteSecret(&secretsmanager.DeleteSecretInput{
				SecretId:                   aws.String(secretName),
				ForceDeleteWithoutRecovery: aws.Bool(true),
			})
			
			if err != nil {
				log.Printf("Warning: Failed to delete secret %s: %v", secretName, err)
			} else {
				deletedCount++
			}
		}
	}

	log.Printf("Cleanup completed. Deleted %d test secrets.", deletedCount)

	// Additional cleanup for any remaining test resources using the same secret list
	cleanupByTags(svc, allSecrets)
}

func cleanupByTags(svc *secretsmanager.SecretsManager, secrets []*secretsmanager.SecretListEntry) {
	log.Println("Performing tag-based cleanup...")

	deletedCount := 0
	for _, secret := range secrets {
		if secret.Name == nil {
			continue
		}

		// Check if secret has test-related tags
		shouldDelete := false
		for _, tag := range secret.Tags {
			if tag.Key != nil && tag.Value != nil {
				key := strings.ToLower(*tag.Key)
				value := strings.ToLower(*tag.Value)
				
				if (key == "environment" && value == "test") ||
				   (key == "managedby" && value == "terratest") ||
				   (key == "testrun" && value != "") ||
				   (key == "purpose" && strings.Contains(value, "test")) {
					shouldDelete = true
					break
				}
			}
		}

		if shouldDelete {
			log.Printf("Deleting tagged test secret: %s", *secret.Name)
			
			_, err := svc.DeleteSecret(&secretsmanager.DeleteSecretInput{
				SecretId:                   secret.Name,
				ForceDeleteWithoutRecovery: aws.Bool(true),
			})
			
			if err != nil {
				log.Printf("Warning: Failed to delete tagged secret %s: %v", *secret.Name, err)
			} else {
				deletedCount++
			}
		}
	}

	log.Printf("Tag-based cleanup completed. Deleted %d additional test secrets.", deletedCount)
}

// isHexString checks if a string contains only hexadecimal characters
func isHexString(s string) bool {
	if len(s) < 6 {
		return false
	}
	matched, _ := regexp.MatchString("^[a-fA-F0-9]+$", s)
	return matched
}

// isNumericString checks if a string contains only numeric characters
func isNumericString(s string) bool {
	if len(s) < 6 {
		return false
	}
	matched, _ := regexp.MatchString("^[0-9]+$", s)
	return matched
}