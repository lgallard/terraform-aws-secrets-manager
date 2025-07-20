terraform {
  required_version = ">= 1.11" # Required for write-only arguments
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.67.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}