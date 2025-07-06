variable "aws_region" {
  description = "AWS region for testing"
  type        = string
  default     = "us-east-1"
}

variable "test_name" {
  description = "Name prefix for test resources"
  type        = string
}
