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
