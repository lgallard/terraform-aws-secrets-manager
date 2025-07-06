# Makefile for terraform-aws-secrets-manager testing

.PHONY: help test test-basic test-key-value test-binary test-validation test-all lint fmt validate clean

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Test targets
test: test-all ## Run all tests (alias for test-all)

test-basic: ## Run basic functionality tests
	cd test && go test -v -timeout 60m -run TestSecretsManagerBasic

test-key-value: ## Run key-value secrets tests
	cd test && go test -v -timeout 60m -run TestSecretsManagerKeyValue

test-binary: ## Run binary secrets tests
	cd test && go test -v -timeout 60m -run TestSecretsManagerBinary

test-validation: ## Run validation tests
	cd test && go test -v -timeout 60m -run TestSecretsManagerValidation

test-all: ## Run all tests
	cd test && go test -v -timeout 60m ./...

test-parallel: ## Run all tests in parallel (faster but uses more resources)
	cd test && go test -v -timeout 60m -parallel 4 ./...

# Development targets
deps: ## Download Go dependencies
	cd test && go mod download && go mod tidy

lint: ## Run linting checks
	terraform fmt -check=true -diff=true
	cd test && go vet ./...
	cd test && go fmt ./...

fmt: ## Format code
	terraform fmt -recursive
	cd test && go fmt ./...

validate: ## Validate Terraform configuration
	terraform init
	terraform validate

# CI targets
ci-test: deps lint validate test-all ## Run all CI checks

# Cleanup targets
clean: ## Clean up temporary files
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.log
	cd test && go clean -testcache

clean-fixtures: ## Clean up test fixtures
	find test/fixtures -name ".terraform" -type d -exec rm -rf {} +
	find test/fixtures -name ".terraform.lock.hcl" -delete
	find test/fixtures -name "terraform.tfstate*" -delete

# Debug targets
debug-basic: ## Run basic tests with debug output
	cd test && TF_LOG=DEBUG go test -v -timeout 60m -run TestSecretsManagerBasic

debug-validation: ## Run validation tests with debug output
	cd test && TF_LOG=DEBUG go test -v -timeout 60m -run TestSecretsManagerValidation

# Check AWS credentials
check-aws: ## Check AWS credentials are configured
	@aws sts get-caller-identity > /dev/null && echo "✅ AWS credentials are configured" || echo "❌ AWS credentials not found"

# Pre-commit checks
pre-commit: fmt lint validate ## Run pre-commit checks

# Documentation
docs: ## Generate documentation
	@echo "📚 Testing documentation is in TESTING.md"
	@echo "📋 See 'make help' for available commands"
