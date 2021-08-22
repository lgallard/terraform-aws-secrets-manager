#!/bin/sh

module_name=$1

# Rotation secret
for secret in $(terraform state list module.${module_name}.aws_secretsmanager_secret.rsm)
do
  name=$(terraform state show ${secret} | grep name | cut -d "\"" -f2)
  index=$(echo  ${secret} | cut -d "[" -f2 | cut -d "]" -f1)
  terraform state mv module.${module_name}.aws_secretsmanager_secret.rsm[${index}] module.${module_name}.aws_secretsmanager_secret.rsm["${name}"]
  terraform state mv module.${module_name}.aws_secretsmanager_secret_version.rsm-sv[${index}] module.${module_name}.aws_secretsmanager_secret_version.rsm-sv["${name}"]

  # Unmanaged - Uncomment to migrate unmanaged unmanaged rotation secret versions
  #terraform state mv module.${module_name}.aws_secretsmanager_secret_version.rsm-svu[${index}] module.${module_name}.aws_secretsmanager_secret_version.rsm-svu["${name}"]
done
