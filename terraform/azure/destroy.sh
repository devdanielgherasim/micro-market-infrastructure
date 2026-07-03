#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-prod}"
PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"

# Credentials must come from environment variables consumed by the azurerm
# provider. Use ARM_USE_OIDC=true plus ARM_OIDC_TOKEN for federated auth, or
# ARM_CLIENT_SECRET for local service-principal auth.
: "${ARM_CLIENT_ID:?Set ARM_CLIENT_ID}"
: "${ARM_TENANT_ID:?Set ARM_TENANT_ID}"
: "${ARM_SUBSCRIPTION_ID:?Set ARM_SUBSCRIPTION_ID}"
if [[ "${ARM_USE_OIDC:-false}" != "true" ]]; then
  : "${ARM_CLIENT_SECRET:?Set ARM_CLIENT_SECRET, or set ARM_USE_OIDC=true with ARM_OIDC_TOKEN}"
fi

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

terraform destroy --var-file="./tfvars_files/$WORKSPACE.tfvars" -var project_name="$PROJECT_NAMESPACE"

# terraform force-unlock <LOCK_ID>
