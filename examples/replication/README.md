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

AWS Secrets Manager replication copies the secret value to the replica regions, but **not** the resource policy. Set `replicate_policy = true` on a secret to have the module apply the primary secret's `policy` to every replica region, so policy updates on the source secret propagate to all replicas on the next apply.

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
}
```

NOTE: Because the same policy document is applied in every region, use region-agnostic statements (e.g. `resources = ["*"]`, which scopes to the attached secret) rather than hardcoding the primary secret's ARN.

NOTE: Replication is asynchronous. On the very first apply that enables replication, a replica may still be provisioning when its policy is applied; if AWS returns `ResourceNotFoundException`, simply re-run `terraform apply`.
