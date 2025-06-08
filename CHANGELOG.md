## 0.11.5 (June 3, 2024)

ENHANCEMENTS:

* Add Renovate

## [0.12.2](https://github.com/lgallard/terraform-aws-secrets-manager/compare/0.12.1...0.12.2) (2025-06-08)


### Bug Fixes

* Add GitHub Action step to remove "v" prefix from release titles ([#68](https://github.com/lgallard/terraform-aws-secrets-manager/issues/68)) ([5f0233d](https://github.com/lgallard/terraform-aws-secrets-manager/commit/5f0233d66849ee6b25bb47fc8ad588f69c416726))

## [0.12.1](https://github.com/lgallard/terraform-aws-secrets-manager/compare/0.12.0...0.12.1) (2025-06-08)


### Bug Fixes

* Add tag-separator configuration to ensure Release Please creates tags without prefixes ([#65](https://github.com/lgallard/terraform-aws-secrets-manager/issues/65)) ([c37f85e](https://github.com/lgallard/terraform-aws-secrets-manager/commit/c37f85e1b2d7660c7415e67bc0c3f44a82c55fc5))

## [0.12.0](https://github.com/lgallard/terraform-aws-secrets-manager/compare/0.11.5...0.12.0) (2025-06-08)


### Features

* Add release-please support ([#62](https://github.com/lgallard/terraform-aws-secrets-manager/issues/62)) ([e84b772](https://github.com/lgallard/terraform-aws-secrets-manager/commit/e84b7729e83b762745c55da164ce85b1a759745d))
* Add release-please workflow  ([4965e14](https://github.com/lgallard/terraform-aws-secrets-manager/commit/4965e1405029cd86a1a355827766cf6791783114))

## 0.11.4 (June 3, 2024)

FIX:

* Fix required constraints
* Remove Dependabot

## 0.11.3 (June 3, 2024)

FIX:

* Change Terraform version requirements syntax

## 0.11.2 (June 3, 2024)

FIX:

* Terraform version requirements syntax

## 0.11.1 (June 3, 2024)

ENHANCEMENTS:

* Add Dependabot

## 0.11.0 (December 19, 2023)

ENHANCEMENTS:

* Allow to use ´version_stages´ on secret versions (thanks @magmax)

## 0.10.1 (October 29, 2023)

FIXES:

* Not defined index in context issue

## 0.10.0 (October 26, 2023)

FIXES:

* Update secret version and secret rotation to support using name_prefix (thanks @bensharp1)
* Allow 'Name' parameter to overwrite each.key as Secret Name (thanks @bensharp1)

## 0.9.0 (September 8, 2023)

ENHANCEMENTS:

* Allow empty replica region `kms_key_id` to use AWS default (thanks @siteopsio)
* Update README file in replication example (thanks @siteopsio)

## 0.8.0 (April 28, 2023)

ENHANCEMENTS:

* Add ´force_overwrite_replica_secret´ (thanks @btougeiro)
* Add replication example

## 0.7.0 (April 5, 2023)

ENHANCEMENTS:

* Add separate secrets replication configuration (thanks @wiseelf)

## 0.6.2 (January 11, 2023)

FIXES:

  * Add lifecycle ignore for `secret_id` (thanks @jmonte-sph)

## 0.6.1 (October 19, 2022)

FIXES:

  * Patch for the missing dependency in the "rsm-sr" resource (thanks @cschwarze)

## 0.6.0 (Sep 1, 2022)

ENHANCEMENTS:

  * Adding Replica support to Secrets (thanks @ppapishe)

## 0.5.3 (Aug 29, 2022)

ENHANCEMENTS:

  * Adds replica support

## 0.5.2 (Jan 2, 2022)

ENHANCEMENTS:

  * Add secret policy examples

## 0.5.1 (August 26, 2021)

FIXES:

  * Fix secret map output

## 0.5.0 (August 22, 2021)

ENHANCEMENTS:

  * Change secret list to map definitions
  * Update READMEs

## 0.4.2 (June 10, 2021)

ENHANCEMENTS:

  * Add pre-commit script
  * Update README

## 0.4.1 (December 1, 2020)

FIXES:

  * Fix typo in README and improve variable description

## 0.4.0 (December 1, 2020)

ENHANCEMENTS:

  * Add support for unmanaged rotated secrets:  Avoid rotation of secrets by subsequent runs of Terraform

Thanks @moliver-aicradle

## 0.3.0 (October 22, 2020)

ENHANCEMENTS:

  * Add support for unmanaged secrets:  Using this option you can initialize the secrets and rotate them outside Terraform, thus, avoiding other users to change the secrets.

Thanks @fabio42

## 0.2.1 (July 3, 2020)

ENHANCEMENTS:

  * Update rotation lambda example

## 0.2.0 (June 29, 2020)

FIXES:

  * Add AWS provider version requirement

## 0.1.2 (June 27, 2020)

FIXES:

  * Fix typo in README

## 0.1.1 (June 26, 2020)

FIXES:

  * Update README

## 0.1.0 (June 26, 2020)

FEATURES:

  * Module implementation
