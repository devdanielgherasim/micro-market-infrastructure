#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BOOTSTRAP_ENV_FILE="${BOOTSTRAP_ENV_FILE:-${SCRIPT_DIR}/../../../utilities/scripts/.env.bootstrap}"

# shellcheck source=./scripts/_common.sh
source "${SCRIPT_DIR}/scripts/_common.sh"

configure_azure_terraform_environment
terraform_init_azure_backend --upgrade
select_or_create_workspace

terraform plan --var-file="${VAR_FILE}" -var project_name="$PROJECT_NAMESPACE" -out=tfplan

echo ""
echo "=== [CONFIRMATION] Review the plan above. Apply these Azure infrastructure changes? (yes/no) ==="
read -r confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" == "yes" ]]; then
  terraform apply tfplan
else
  echo "=== [INFO] Apply cancelled by user ==="
  rm -f tfplan
  exit 0
fi

rm -f tfplan

echo "=== [INFO] Syncing keycloak-dns values from Terraform outputs ==="
python3 "${SCRIPT_DIR}/scripts/sync_keycloak_dns.py" || echo "=== [WARN] keycloak-dns sync failed - update platform-gitops/platform/keycloak-dns/values.yaml manually (see ADR-19) ==="

# terraform force-unlock <LOCK_ID>
