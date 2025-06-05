#!/bin/bash

export GOOGLE_APPLICATION_CREDENTIALS="../i-binder-461513-v8-40884e000270.json"

terraform init \
  -backend-config="bucket=terraformmicroservicesstate" \
  -backend-config="prefix=terraform/environments/dev/state"

terraform apply --var-file=./tfvars_files/dev.tfvars \
  --var project_id="i-binder-461513-v8" \
  --var credentials_file="../i-binder-461513-v8-40884e000270.json"

# terraform force-unlock <LOCK_ID>
