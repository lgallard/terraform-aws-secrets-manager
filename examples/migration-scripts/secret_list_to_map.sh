#!/bin/sh

module_name=$1

# Secret
for secret in $(terraform state list module.${module_name}.aws_secretsmanager_secret.sm)
do
  name=$(terraform state show ${secret} | grep name | cut -d "\"" -f2)
  index=$(echo  ${secret} | cut -d "[" -f2 | cut -d "]" -f1)
  terraform state mv module.${module_name}.aws_secretsmanager_secret.sm[${index}] module.${module_name}.aws_secretsmanager_secret.sm["${name}"]
  terraform state mv module.${module_name}.aws_secretsmanager_secret_version.sm-sv[${index}] module.${module_name}.aws_secretsmanager_secret_version.sm-sv["${name}"]

  # Unmanaged - Uncomment to migrate unmanaged unmanaged secret versions
  #terraform state mv module.${module_name}.aws_secretsmanager_secret_version.sm-svu[${index}] module.${module_name}.aws_secretsmanager_secret_version.sm-svu["${name}"]
done
