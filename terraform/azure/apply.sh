#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-prod}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"

# Credentials must come from the environment (ARM_* preferred by azurerm,
# TF_VAR_* consumed by this module's variables). Never hardcode them here.
: "${TF_VAR_client_id:?Set TF_VAR_client_id (Azure service principal appId)}"
: "${TF_VAR_client_secret:?Set TF_VAR_client_secret (Azure service principal secret)}"
: "${TF_VAR_tenant_id:?Set TF_VAR_tenant_id}"
: "${TF_VAR_subscription_id:?Set TF_VAR_subscription_id}"

terraform init

if ! terraform workspace list | grep -q "$WORKSPACE"; then
  echo "=== [DEBUG] Creating new workspace: $WORKSPACE ==="
  terraform workspace new "$WORKSPACE"
else
  echo "=== [DEBUG] Workspace $WORKSPACE already exists ==="
fi
echo "=== [DEBUG] Selecting workspace: $WORKSPACE ==="
terraform workspace select "$WORKSPACE"
echo "=== [DEBUG] Current workspace: $(terraform workspace show) ==="

terraform plan --var-file="./tfvars_files/$WORKSPACE.tfvars" -var project_name="$PROJECT_NAMESPACE" -out=tfplan

terraform apply tfplan

rm -f tfplan

# terraform force-unlock <LOCK_ID>
