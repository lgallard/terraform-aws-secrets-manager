terraform {
  required_version = ">= v0.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.67.0"
    }
  }
}
