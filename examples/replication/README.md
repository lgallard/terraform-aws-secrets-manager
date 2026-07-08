# Plain text example
```
module "secrets-manager-6" {

  source = "lgallard/secrets-manager/aws"

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
  }

  tags = {
    Owner       = "DevOps team"
    Environment = "dev"
    Terraform   = true
  }

}
```

NOTE: If you leave the replica_regions with an empty map it will use the default KMS key for that region.
```
    replica_regions = {
      us-west-2 = {}
      us-west-1 = "arn:aws:kms:us-west-1:1234567890:key/12345678-1234-1234-1234-123456789012"

    }

```

# Replicating the resource policy

AWS Secrets Manager replication copies encrypted secret data and metadata, including resource policies, to replica regions. Configure `policy` on the primary regular or rotating secret; AWS propagates that policy to replicas automatically.

```
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

  source = "lgallard/secrets-manager/aws"

  secrets = {
    secret-with-policy = {
      description             = "Secret whose resource policy is replicated by AWS"
      recovery_window_in_days = 7
      secret_string           = "This is an example"
      policy                  = data.aws_iam_policy_document.secret_policy.json
      replica_regions = {
        us-west-2 = "arn:aws:kms:us-west-2:1234567890:key/12345678-1234-1234-1234-123456789012"
        us-east-2 = "arn:aws:kms:us-east-2:1234567890:key/12345678-1234-1234-1234-123456789012"
      }
      force_overwrite_replica_secret = true
    },
  }

  rotate_secrets = {
    rotating-secret-with-policy = {
      description             = "Rotating secret whose resource policy is replicated by AWS"
      recovery_window_in_days = 7
      secret_string           = "This is a rotating example"
      rotation_lambda_arn     = "arn:aws:lambda:us-east-1:123456789012:function:lambda-rotate-secret"
      policy                  = data.aws_iam_policy_document.secret_policy.json
      replica_regions = {
        us-west-2 = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
        eu-west-1 = {
          region     = "eu-west-1"
          kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/87654321-4321-4321-4321-210987654321"
        }
      }
    }
  }
}
```

NOTE: Policy replication is asynchronous. AWS rejects direct resource-policy updates against replica secrets; update the primary secret policy instead. If a replica must diverge, promote it to a standalone secret first.

NOTE: Rotating secrets (`rotate_secrets`) support `replica_regions` using the same input shape as regular `secrets`. If you previously set `replica_regions` under `rotate_secrets`, version 1.2.0 and later manage those replicas instead of ignoring that attribute.
