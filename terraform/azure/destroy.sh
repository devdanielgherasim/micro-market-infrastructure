#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
BOOTSTRAP_ENV_FILE="${BOOTSTRAP_ENV_FILE:-${SCRIPT_DIR}/../../../utilities/scripts/.env.bootstrap}"

# shellcheck source=./scripts/_common.sh
source "${SCRIPT_DIR}/scripts/_common.sh"

configure_azure_terraform_environment
terraform_init_azure_backend
select_or_create_workspace

terraform plan -destroy --var-file="${VAR_FILE}" -var project_name="$PROJECT_NAMESPACE" -out=tfplan

echo ""
echo "=== [CONFIRMATION] Review the destroy plan above. Destroy Azure infrastructure? (yes/no) ==="
read -r confirmation
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [[ "$confirmation" == "yes" ]]; then
  terraform apply tfplan
else
  echo "=== [INFO] Destroy cancelled by user ==="
  rm -f tfplan
  exit 0
fi

rm -f tfplan

# terraform force-unlock <LOCK_ID>
