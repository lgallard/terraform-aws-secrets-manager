terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.50.0"
    }
  }
}

# Resource policy applied to the primary secret and, via replicate_policy,
# to every replica region as well.
data "aws_iam_policy_document" "secret_policy" {
  statement {
    sid    = "AllowApplicationAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::123456789012:role/MyApplicationRole"]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

module "secrets-manager-6" {

  #source = "lgallard/secrets-manager/aws"
  source = "../../"

  secrets = {
    secret-plain = {
      description             = "My plain text secret"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
      replica_regions = {
        us-west-2 = "arn:aws:kms:us-west-2:1234567890:key/12345678-1234-1234-1234-123456789012"
      }
      force_overwrite_replica_secret = true
    },
    secret-key-value = {
      description = "This is a key/value secret"
      secret_key_value = {
        username = "user"
        password = "topsecret"
      }
      replica_regions = {
        us-west-1 = "arn:aws:kms:us-west-1:1234567890:key/12345678-1234-1234-1234-123456789012"
      }
      force_overwrite_replica_secret = false
      tags = {
        app = "web"
      }
      recovery_window_in_days = 7
    },
    secret-with-policy = {
      description             = "Secret whose resource policy is kept in sync on every replica"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
      policy                  = data.aws_iam_policy_document.secret_policy.json
      replicate_policy        = true
      replica_regions = {
        us-west-2 = "arn:aws:kms:us-west-2:1234567890:key/12345678-1234-1234-1234-123456789012"
        us-east-2 = "arn:aws:kms:us-east-2:1234567890:key/12345678-1234-1234-1234-123456789012"
      }
      force_overwrite_replica_secret = true
    },
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }

}
