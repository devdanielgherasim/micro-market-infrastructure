#!/bin/bash
WORKSPACE="prod"
PROJECT_NAMESPACE="microservices1691712"

echo "=== [DEBUG] Configuring Azure provider ==="

export TF_VAR_client_id=""
export TF_VAR_client_secret=""
export TF_VAR_tenant_id=""
export TF_VAR_subscription_id=""

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

terraform destroy --var-file=./tfvars_files/$WORKSPACE.tfvars -var project_name="$PROJECT_NAMESPACE"

# terraform force-unlock <LOCK_ID>
