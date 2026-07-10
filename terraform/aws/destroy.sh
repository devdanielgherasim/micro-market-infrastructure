#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-dev}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
STATE_BUCKET="${TF_STATE_BUCKET:-terraform-state-${AWS_ACCOUNT_ID}-${AWS_REGION}}"
STATE_KEY="${TF_STATE_KEY:-aws/${ENVIRONMENT}/terraform.tfstate}"
VAR_FILE="./tfvars_files/${ENVIRONMENT}.tfvars"

if [[ ! -f "${VAR_FILE}" ]]; then
  echo "Missing variable file: ${VAR_FILE}" >&2
  exit 1
fi

terraform init -reconfigure \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="use_lockfile=true"

terraform workspace select "${ENVIRONMENT}" 2>/dev/null || true

terraform plan -destroy \
  -var-file="${VAR_FILE}" \
  -out=tfplan.destroy

echo
echo "WARNING: this will destroy ALL infrastructure in environment '${ENVIRONMENT}'."
read -rp "Type 'yes' to confirm: " CONFIRM
if [[ "${CONFIRM}" != "yes" ]]; then
  echo "Aborted."
  rm -f tfplan.destroy
  exit 0
fi

terraform apply tfplan.destroy
rm -f tfplan.destroy
