package main

import (
	"log"
	"os"
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
	}

	log.Printf("Starting cleanup of test secrets in region %s", region)

	// List all secrets
	input := &secretsmanager.ListSecretsInput{}
	result, err := svc.ListSecrets(input)
	if err != nil {
		log.Fatalf("Failed to list secrets: %v", err)
	}

	deletedCount := 0
	for _, secret := range result.SecretList {
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

		// Also check for secrets created in the last 24 hours with test-like patterns
		if !shouldDelete && secret.CreatedDate != nil {
			timeSinceCreation := time.Since(*secret.CreatedDate)
			if timeSinceCreation < 24*time.Hour {
				// Check for common test patterns
				testPatterns := []string{
					"test-",
					"terratest-",
					"ephemeral-",
					"validation-",
				}
				for _, pattern := range testPatterns {
					if strings.Contains(strings.ToLower(secretName), pattern) {
						shouldDelete = true
						break
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

	// Additional cleanup for any remaining test resources
	cleanupByTags(svc)
}

func cleanupByTags(svc *secretsmanager.SecretsManager) {
	log.Println("Performing tag-based cleanup...")

	input := &secretsmanager.ListSecretsInput{}
	result, err := svc.ListSecrets(input)
	if err != nil {
		log.Printf("Failed to list secrets for tag cleanup: %v", err)
		return
	}

	deletedCount := 0
	for _, secret := range result.SecretList {
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