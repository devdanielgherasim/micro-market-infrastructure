#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"

terraform init

if ! terraform workspace list | grep -q "$WORKSPACE"; then
  terraform workspace new "$WORKSPACE"
else
  terraform workspace select "$WORKSPACE"
fi

terraform plan --var-file="./tfvars_files/$WORKSPACE.tfvars" -var project_name="$PROJECT_NAMESPACE" -out=tfplan
terraform apply tfplan
rm -f tfplan

# terraform force-unlock <LOCK_ID>
