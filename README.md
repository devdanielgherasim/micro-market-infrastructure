# infrastructure

Terraform for the cloud compute layer of the microservices dissertation project. Provisions the managed Kubernetes cluster and everything a cluster needs from the cloud provider itself (network, container registry, KMS keys, workload identity) for exactly one cloud at a time — **AWS (EKS), Azure (AKS), or GCP (GKE)**, all three treated as equal, interchangeable targets that get spun up, demoed, and torn down independently. Everything that runs *inside* the cluster (ArgoCD, Istio, observability, Keycloak, the microservices themselves) is out of scope here — see `../kubernetes-infrastructure` and `../platform-gitops`.

> **Branch note:** this repo is currently checked out on `prod` (not `main`/`dev`). That's pre-existing state, not something this README changes.

## Layout

Each cloud gets its own root under `terraform/`, split into the same file shape:

```
terraform/{aws,azure,gcp}/
  network.tf     # VPC/VNet + subnets
  cluster.tf     # EKS / AKS / GKE cluster + node pool(s)
  registry.tf    # ECR / ACR / Artifact Registry
  identity.tf    # IRSA / workload identity federation / GitLab-OIDC federated auth
  kms.tf         # KMS keys (secrets envelope encryption, ECR/ACR image encryption, etc.)
  secrets.tf     # Seeds the cloud secret manager (Secrets Manager / Key Vault / Secret Manager)
  main.tf, providers.tf, variables.tf, outputs.tf, locals.tf
  tfvars_files/{dev,staging,prod}.tfvars
  apply.sh, destroy.sh
```

AWS additionally has `iam.tf` (EKS IRSA roles, ALB controller policy) and `platform_addon_iam.tf`; GCP additionally has `data.tf`. Azure's split is `network.tf`/`cluster.tf`/`identity.tf`/`kms.tf`/`registry.tf`/`secrets.tf` — same shape, no extra files. Each root also has a `.terraform.lock.hcl` (provider pins: azurerm ~>4.32/4.30 per root, google ~>6.37, aws ~>6.53, random ~>3.9).

None of the three clouds carries an extra post-apply step over the others today — `apply.sh` in all three roots is env-var/workspace-driven with no hardcoded credentials, and the shared `.gitlab-ci.yml` pipeline branches on a single `CLOUD_PROVIDER` variable rather than having a cloud-specific job. (If you've read the sibling workspace's architecture guide and it says Azure is "most complete" with an extra `azure_post_apply` job — that predates this overhaul; all three clouds are structurally parallel now, per project decision.)

## Auth model

No long-lived cloud credentials are stored anywhere in CI. Every cloud authenticates via GitLab OIDC:

- **AWS**: `aws sts assume-role-with-web-identity` using GitLab's own OIDC token (`GITLAB_OIDC_TOKEN`, audience `https://gitlab.com`) against an IAM role (`AWS_ROLE_ARN`), yielding short-lived STS credentials.
- **Azure**: `ARM_USE_OIDC=true` + `ARM_OIDC_TOKEN=$GITLAB_OIDC_TOKEN` against a federated identity credential on an Azure AD app (`ARM_CLIENT_ID`/`ARM_TENANT_ID`/`ARM_SUBSCRIPTION_ID`).
- **GCP**: a hand-built [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) external-account credential file, constructed in CI from `GITLAB_OIDC_TOKEN` + `GCP_WORKLOAD_IDENTITY_PROVIDER` + `GCP_SERVICE_ACCOUNT_EMAIL`, fed to the provider via `GOOGLE_APPLICATION_CREDENTIALS`.

This replaced an earlier state where a real GCP service-account JSON key was committed to the repo (leaked, then rotated and purged — see `SECURITY.md` and the multicloud overhaul plan's Phase 0 for the incident). `.gitignore` now blocks `tfplan*`, `plan.json`, `*.tfstate*`, `i-binder-*.json`, `*.pem`/`*.p12`/`*.pfx`, and kubeconfigs; `.terraform.lock.hcl` is deliberately **not** ignored (HashiCorp's own guidance — commit it for reproducible provider resolution). A `.githooks/pre-commit` (gitleaks) and a GitLab Secret-Detection CI job (`.gitlab-ci.yml`'s `secret_detection` job, `validate` stage) both gate against reintroducing secrets.

## Backend

Each root's state lives in a cloud-native remote backend: AWS in S3 (bucket `terraform-microservices1691715-state`, key `aws/<workspace>/terraform.tfstate`, native S3 locking via `use_lockfile=true`), Azure in an `azurerm` storage-account backend with Terraform workspaces, and GCP in GCS with the prefix supplied at init time as `terraform/environments/<workspace>/state`. CI selects the backend by running `terraform init -backend-config=...`, using values assembled from environment variables; GCP no longer hardcodes the `dev` prefix in `main.tf`.

`terraform/gcp/REMOTE_BACKEND_SETUP.md` documents the one-time GCS bucket bootstrap for that cloud.

## CI pipeline (`.gitlab-ci.yml`)

Single pipeline, parameterized by `CLOUD_PROVIDER` (default `aws`; also accepts `azure`/`gcp`), stages:

```
validate → plan → apply (manual) → destroy (manual)
```

- `validate_infrastructure`: `terraform init` (with the OIDC-derived backend args for the selected cloud) → `terraform validate` → `terraform fmt -check -diff`.
- `checkov`: static IaC security scan (`bridgecrew/checkov:latest -d terraform/ --config-file .checkov.yaml`), run in the `validate` stage but deliberately independent of `validate_infrastructure`'s init/plugins — a checkov finding never blocks on an unrelated fmt/validate failure and vice versa. It scans all three cloud roots regardless of `CLOUD_PROVIDER`.
- `plan_infrastructure`: creates/selects a Terraform workspace named after the (sanitized) branch, runs `terraform plan --var-file=tfvars_files/$WORKSPACE.tfvars`, uploads `tfplan` + a `plan.json` (consumed by GitLab's native Terraform plan-diff MR widget).
- `apply_infrastructure` / `destroy_infrastructure`: both `when: manual`, apply the saved plan / destroy the selected workspace.

`checkov` doesn't do its own severity lookup here (that needs a Bridgecrew/Prisma API call); every finding was triaged individually and is either fixed directly in the Terraform or accepted with a per-check-ID, per-reason entry in `.checkov.yaml`.

### `.checkov.yaml` shape

Roughly 30 skip-check entries, grouped by area with an inline comment on every single one explaining *why* it's an accepted lab-scope tradeoff rather than a real gap:

- **AWS**: permissive dev-only EKS public endpoint (CI runners have non-static egress IPs), no Secrets Manager auto-rotation (secrets are regenerated fresh every apply/destroy cycle), KMS key policies that intentionally replicate AWS's own unconstrained default (`kms:*` for the account root, real authorization lives in IAM), CloudWatch flow-log group without a dedicated CMK.
- **Azure (AKS)**: no authorized-IP-ranges/private cluster (same CI-runner reachability constraint), no CMK on temp-disk/OS-disk encryption, no ephemeral OS disks, no paid-SLA tier, no AAD-RBAC-gated local admin disable, no redundant Azure Monitor (the in-cluster kube-prometheus-stack/Loki/Tempo stack already covers this), single node pool, no Key Vault CSI driver (secrets come via External Secrets Operator instead).
- **Azure (ACR)**: no Defender-for-Containers scanning or legacy content-trust (Trivy + cosign in CI already cover image scanning/signing), Premium-SKU-only features (geo-replication, private endpoints, retention policies) skipped as a Basic-SKU cost decision.
- **Azure (Key Vault)**: no private endpoint (same CI-runner reachability point), purge protection intentionally off (mirrors AWS's `recovery_window_in_days=0` — lets `terraform destroy` cleanly remove the vault every demo cycle).
- **GCP (GKE)**: no Binary Authorization (cosign verify gate already covers image provenance), no flow logs on the project's default VPC (this root doesn't manage a dedicated VPC to attach one to), no Google-Groups RBAC (no Workspace domain for this lab), no master-authorized-networks (CI-runner IP constraint again), no private cluster/nodes (same default-VPC reasoning).

Findings that were genuinely fixable were fixed directly instead of skipped: full EKS control-plane log types, IAM policies narrowed from `Resource: "*"` to project/env-scoped Secrets Manager ARNs, explicit-but-standard KMS key policies, default-SG lockdown + VPC flow logs, AKS auto-upgrade channel + Azure Policy add-on, and GKE alias IPs/release channel/workload-identity metadata mode/Shielded VMs/Artifact Registry CMEK.

## Local dev caveat

On at least one prior development machine, `terraform validate`/`plan` fails locally with `x509: certificate signed by unknown authority` — this is **Norton's TLS-interception IDS module (aswidsagent)** intercepting the loopback handshake between the `terraform` binary and its downloaded provider plugins, not a bug in this repo. Add a Norton exclusion for `terraform.exe` and `.terraform\providers\**\*.exe` (or disable Norton's traffic inspection for those processes) to unblock local runs. GitLab CI runners are unaffected.

## Which cloud is most complete

All three are intentionally at parity today (network/cluster/registry/identity/kms/secrets, identical CI pipeline shape, identical checkov gating) — this is a deliberate outcome of the multicloud overhaul, not an accident. There is no cloud-specific bootstrap step left over from an earlier, less-parallel design.
