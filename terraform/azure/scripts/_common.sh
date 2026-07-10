#!/usr/bin/env bash

load_bootstrap_env_defaults() {
  local old_environment="${ENVIRONMENT-}"
  local old_workspace="${WORKSPACE-}"
  local old_project_namespace="${PROJECT_NAMESPACE-}"
  local old_arm_client_id="${ARM_CLIENT_ID-}"
  local old_arm_client_secret="${ARM_CLIENT_SECRET-}"
  local old_arm_tenant_id="${ARM_TENANT_ID-}"
  local old_arm_subscription_id="${ARM_SUBSCRIPTION_ID-}"
  local old_arm_use_oidc="${ARM_USE_OIDC-}"
  local old_azure_rg="${AZURE_TF_STATE_RESOURCE_GROUP-}"
  local old_azure_account="${AZURE_TF_STATE_STORAGE_ACCOUNT-}"
  local old_azure_container="${AZURE_TF_STATE_CONTAINER-}"

  if [[ -f "${BOOTSTRAP_ENV_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${BOOTSTRAP_ENV_FILE}"
    echo "=== [INFO] Loaded defaults from ${BOOTSTRAP_ENV_FILE} ==="
  fi

  [[ -n "${old_environment}" ]] && ENVIRONMENT="${old_environment}"
  [[ -n "${old_workspace}" ]] && WORKSPACE="${old_workspace}"
  [[ -n "${old_project_namespace}" ]] && PROJECT_NAMESPACE="${old_project_namespace}"
  [[ -n "${old_arm_client_id}" ]] && ARM_CLIENT_ID="${old_arm_client_id}"
  [[ -n "${old_arm_client_secret}" ]] && ARM_CLIENT_SECRET="${old_arm_client_secret}"
  [[ -n "${old_arm_tenant_id}" ]] && ARM_TENANT_ID="${old_arm_tenant_id}"
  [[ -n "${old_arm_subscription_id}" ]] && ARM_SUBSCRIPTION_ID="${old_arm_subscription_id}"
  [[ -n "${old_arm_use_oidc}" ]] && ARM_USE_OIDC="${old_arm_use_oidc}"
  [[ -n "${old_azure_rg}" ]] && AZURE_TF_STATE_RESOURCE_GROUP="${old_azure_rg}"
  [[ -n "${old_azure_account}" ]] && AZURE_TF_STATE_STORAGE_ACCOUNT="${old_azure_account}"
  [[ -n "${old_azure_container}" ]] && AZURE_TF_STATE_CONTAINER="${old_azure_container}"
}

configure_azure_terraform_environment() {
  load_bootstrap_env_defaults

  AZURE_TF_STATE_RESOURCE_GROUP="${AZURE_TF_STATE_RESOURCE_GROUP:-${AZURE_STATE_RESOURCE_GROUP:-rg-infrastructure}}"
  AZURE_TF_STATE_STORAGE_ACCOUNT="${AZURE_TF_STATE_STORAGE_ACCOUNT:-${AZURE_STATE_STORAGE_ACCOUNT:-}}"
  AZURE_TF_STATE_CONTAINER="${AZURE_TF_STATE_CONTAINER:-${AZURE_STATE_CONTAINER:-tfstate}}"

  WORKSPACE="${WORKSPACE:-${ENVIRONMENT:-prod}}"
  PROJECT_NAMESPACE="${PROJECT_NAMESPACE:-danielgherasim-microservices}"
  VAR_FILE="./tfvars_files/${WORKSPACE}.tfvars"
  [[ -f "${VAR_FILE}" ]] || { echo "ERROR: ${VAR_FILE} not found" >&2; exit 1; }

  # Credentials must come from environment variables consumed by the azurerm
  # provider. Use ARM_USE_OIDC=true plus ARM_OIDC_TOKEN for federated auth, or
  # ARM_CLIENT_SECRET for local service-principal auth.
  : "${ARM_CLIENT_ID:?Set ARM_CLIENT_ID}"
  : "${ARM_TENANT_ID:?Set ARM_TENANT_ID}"
  : "${ARM_SUBSCRIPTION_ID:?Set ARM_SUBSCRIPTION_ID}"
  if [[ "${ARM_USE_OIDC:-false}" != "true" ]]; then
    : "${ARM_CLIENT_SECRET:?Set ARM_CLIENT_SECRET, or set ARM_USE_OIDC=true with ARM_OIDC_TOKEN}"
  fi

  export ARM_CLIENT_ID
  export ARM_TENANT_ID
  export ARM_SUBSCRIPTION_ID
  export ARM_USE_OIDC="${ARM_USE_OIDC:-false}"
  if [[ "${ARM_USE_OIDC}" != "true" ]]; then
    export ARM_CLIENT_SECRET
  fi
  export TF_VAR_client_id="${ARM_CLIENT_ID}"
  export TF_VAR_tenant_id="${ARM_TENANT_ID}"
  export TF_VAR_subscription_id="${ARM_SUBSCRIPTION_ID}"
  export TF_VAR_client_secret="${ARM_CLIENT_SECRET:-}"
  export TF_VAR_cloudflare_api_token="${CLOUDFLARE_TOKEN:-${TF_VAR_cloudflare_api_token:-}}"

  if [[ -z "${AZURE_TF_STATE_STORAGE_ACCOUNT}" || "${AZURE_TF_STATE_STORAGE_ACCOUNT}" == "terraformmicrostate" ]]; then
    subscription_part=$(echo "${ARM_SUBSCRIPTION_ID}" | tr -d '-' | tr '[:upper:]' '[:lower:]' | cut -c1-12)
    environment_part=$(echo "${WORKSPACE}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-5)
    AZURE_TF_STATE_STORAGE_ACCOUNT="tfstate${subscription_part}${environment_part}"
  fi
}

terraform_init_azure_backend() {
  local upgrade_flag="${1:-}"
  local init_args=(
    init
    -reconfigure
    -backend-config="resource_group_name=${AZURE_TF_STATE_RESOURCE_GROUP}"
    -backend-config="storage_account_name=${AZURE_TF_STATE_STORAGE_ACCOUNT}"
    -backend-config="container_name=${AZURE_TF_STATE_CONTAINER}"
    -backend-config="key=terraform.tfstate"
  )

  if [[ "${upgrade_flag}" == "--upgrade" ]]; then
    # Apply keeps provider/module upgrades explicit in the forward path.
    # Destroy intentionally avoids upgrade to minimize teardown-time drift.
    init_args+=(--upgrade)
  fi

  terraform "${init_args[@]}"
}

select_or_create_workspace() {
  if ! terraform workspace list | grep -q "$WORKSPACE"; then
    echo "=== [DEBUG] Creating new workspace: $WORKSPACE ==="
    terraform workspace new "$WORKSPACE"
  else
    echo "=== [DEBUG] Workspace $WORKSPACE already exists ==="
  fi
  echo "=== [DEBUG] Selecting workspace: $WORKSPACE ==="
  terraform workspace select "$WORKSPACE"
  echo "=== [DEBUG] Current workspace: $(terraform workspace show) ==="
}
