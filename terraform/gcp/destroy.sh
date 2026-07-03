#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"

terraform init

if ! terraform workspace list | grep -q "$WORKSPACE"; then
  echo "Workspace $WORKSPACE does not exist; cannot destroy it." >&2
  exit 1
fi

terraform workspace select "$WORKSPACE"
terraform destroy --var-file="./tfvars_files/$WORKSPACE.tfvars" -var project_name="$PROJECT_NAMESPACE"

# terraform force-unlock <LOCK_ID>
