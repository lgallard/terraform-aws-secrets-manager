#!/bin/bash

# Simple test runner script for demonstration purposes
# This shows how to run individual test functions

set -e

echo "🚀 Terratest Test Runner"
echo "======================="

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21+ first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please configure AWS credentials."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Change to test directory
cd "$(dirname "$0")"

# Download dependencies
echo "📦 Installing Go dependencies..."
go mod download

# Run the test based on argument
case "${1:-all}" in
    "basic")
        echo "🧪 Running basic functionality tests..."
        go test -v -timeout 60m -run TestSecretsManagerBasic
        ;;
    "key-value")
        echo "🧪 Running key-value secrets tests..."
        go test -v -timeout 60m -run TestSecretsManagerKeyValue
        ;;
    "binary")
        echo "🧪 Running binary secrets tests..."
        go test -v -timeout 60m -run TestSecretsManagerBinary
        ;;
    "validation")
        echo "🧪 Running validation tests..."
        go test -v -timeout 60m -run TestSecretsManagerValidation
        ;;
    "all")
        echo "🧪 Running all tests..."
        go test -v -timeout 60m ./...
        ;;
    *)
        echo "Usage: $0 [basic|key-value|binary|validation|all]"
        echo "  basic      - Run basic functionality tests"
        echo "  key-value  - Run key-value secrets tests"
        echo "  binary     - Run binary secrets tests"
        echo "  validation - Run validation tests"
        echo "  all        - Run all tests (default)"
        exit 1
        ;;
esac

echo ""
echo "✅ Tests completed successfully!"
