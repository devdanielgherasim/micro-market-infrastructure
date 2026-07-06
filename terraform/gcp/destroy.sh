#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-dev}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
STATE_BUCKET="${GCP_TF_STATE_BUCKET:-terraformmicroservicesstate}"
STATE_PREFIX="${GCP_TF_STATE_PREFIX:-terraform/environments/${WORKSPACE}/state}"

terraform init \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="prefix=${STATE_PREFIX}"

if ! terraform workspace list | grep -q "$WORKSPACE"; then
  echo "Workspace $WORKSPACE does not exist; cannot destroy it." >&2
  exit 1
fi

terraform workspace select "$WORKSPACE"
terraform destroy --var-file="./tfvars_files/$WORKSPACE.tfvars" -var project_name="$PROJECT_NAMESPACE"

# terraform force-unlock <LOCK_ID>
