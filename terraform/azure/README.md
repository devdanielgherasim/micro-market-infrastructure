# Azure infrastructure Terraform

This root provisions the Azure leg of the Micro Market platform:

- AKS, ACR, workload identities, Key Vault, managed PostgreSQL, and the Azure
  Container Apps Keycloak instance.
- Per-environment state and variables through Terraform workspaces plus
  `tfvars_files/{dev,staging,prod}.tfvars`.
- Cloudflare-facing Keycloak DNS values exported for the sibling
  `platform-gitops/platform/keycloak-dns` chart.

Use `apply.sh` and `destroy.sh` from this directory. Both scripts load shared
bootstrap defaults from `../../../utilities/scripts/.env.bootstrap` when present,
then let explicit environment variables win.

Required environment:

- `ARM_CLIENT_ID`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`
- either `ARM_CLIENT_SECRET`, or `ARM_USE_OIDC=true` with the provider's OIDC
  token environment already configured
- optionally `WORKSPACE` or `ENVIRONMENT` (`prod` is the script fallback)
- optionally `PROJECT_NAMESPACE`
- optionally `CLOUDFLARE_TOKEN`

The scripts fail before `terraform plan` if
`tfvars_files/${WORKSPACE}.tfvars` is missing.

`apply.sh` runs `terraform init -reconfigure --upgrade`; `destroy.sh` runs
`terraform init -reconfigure` without `--upgrade` to avoid provider/module drift
during teardown.

After a successful apply, `apply.sh` runs `scripts/sync_keycloak_dns.py`, which
reads Terraform outputs and updates the matching Azure records in
`platform-gitops/platform/keycloak-dns/values.yaml`. Review and commit that
sibling-repo diff separately.
