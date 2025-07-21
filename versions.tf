terraform {
  required_version = ">= 1.11.0" # Required for ephemeral resources and write-only arguments

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.67.0"
    }
  }
}
