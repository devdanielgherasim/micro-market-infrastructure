---
status: abandoned
created: 2026-07-02
updated: 2026-07-02
owner: codex
repo: infrastructure
objective: Rebuild the dissertation infrastructure into a professional, secure, production-ready AWS-first multi-cloud platform for danielgherasim.com.
superseded-by: ../../plans/2026-07-03-multicloud-platform-overhaul.md
---

> **Superseded 2026-07-03**: absorbed into the workspace-root plan
> `Sources/plans/2026-07-03-multicloud-platform-overhaul.md` (all-clouds-equal strategy).
> Completed work here is kept; remaining tasks continue in that plan.

# AWS Professional Infrastructure Rebuild

## Context
- Goal: rebuild the infrastructure from scratch for a company-grade dissertation presentation.
- Primary cloud: AWS. Multi-cloud support remains required through `CLOUD_PROVIDER` / environment selection for AWS, Azure, and GCP.
- Domain: `danielgherasim.com` managed in Cloudflare. Cloudflare must be used as DNS/free-tier infrastructure only; do not plan or enable paid Cloudflare features such as WAF, load balancing, Zero Trust, Argo Tunnel, paid bot protection, or paid edge security.
- Workspace repos involved: `infrastructure` for cloud base infrastructure, `kubernetes-infrastructure` for cluster add-ons, `deployment` for Helm/GitOps workloads, and service/frontend repos for CI image publishing.
- Current AWS Terraform was inconsistent: `terraform/aws/main.tf` defined older VPC/EKS/ECR resources while newer files (`network.tf`, `cluster.tf`, `iam.tf`, `kms.tf`, `locals.tf`) defined a more professional private topology. Initial implementation removed the duplicate old AWS resource model from `main.tf`; final module consolidation is still pending.
- Current Kubernetes Terraform has useful add-ons (cert-manager, ingress-nginx, kube-prometheus-stack, Loki, Alloy, Keycloak, PostgreSQL, ArgoCD) but should be reorganized for AWS-first production readiness and Cloudflare DNS/TLS.
- Current deployment Helm charts have basic probes/resources/HPAs but need pod security, network policies, external secrets, stronger ingress, and environment-specific production values.
- Current CI supports `CLOUD_PROVIDER`, but it uses older Terraform images, manual shell logic, and provider credentials. Target should be OIDC-based CI federation and policy/security gates.

## Tasks
- [x] Inspect current workspace guidance and infrastructure layout.
- [x] Record a phased rebuild plan.
- [~] Phase 0: freeze current state, remove generated/secret artifacts from source, and define target architecture.
- [~] Phase 1: rebuild Terraform foundation with remote state, modules, naming, tagging, and multi-cloud interface.
- [~] Phase 2: rebuild AWS foundation: VPC, EKS, ECR, IAM, KMS, DNS/TLS integration, logging, and security baselines.
- [ ] Phase 3: rebuild Kubernetes platform add-ons for AWS-first operation.
- [ ] Phase 4: harden application Helm charts and GitOps delivery.
- [ ] Phase 5: modernize CI/CD, image supply chain, policy checks, and deployment promotion.
- [ ] Phase 6: validate production readiness with security, reliability, performance, observability, and presentation evidence.

## Decisions
- Use AWS as the production-grade reference implementation; keep Azure/GCP as compatible provider backends through a common interface and staged parity.
- Use Cloudflare as DNS authority for `danielgherasim.com`; Terraform should manage DNS records and, if needed, a scoped API token for cert-manager DNS-01 validation. Do not enable Cloudflare WAF or other paid Cloudflare products.
- Prefer managed AWS services and IAM Roles for Service Accounts / EKS Pod Identity over static credentials in Kubernetes.
- Keep PostgreSQL in-cluster only for low-cost demo environments; define RDS PostgreSQL as the professional production target.
- Keep ArgoCD/GitOps, but make Terraform own infrastructure and platform add-ons while ArgoCD owns application workloads.
- Backups and disaster recovery are explicitly out of scope per user direction. Do not add backup vaults, cross-region replication, backup policies, or DR runbooks unless that scope is reopened later.

## Validation
- Current file discovery completed for `infrastructure`, `kubernetes-infrastructure`, and `deployment`.
- Official guidance considered: AWS Well-Architected Framework, AWS EKS Best Practices Guide, Terraform S3 backend documentation, and Cloudflare Terraform provider documentation.
- No implementation changes have been made yet beyond this plan.
- User clarified that Cloudflare paid features are out of scope. The plan was updated to DNS/free-tier Cloudflare usage only.
- Initial AWS implementation started:
  - Replaced old duplicate `terraform/aws/main.tf` VPC/EKS/ECR resources with ECR-only resources keyed by `application_names`.
  - ECR repositories now use immutable tags, scan-on-push, lifecycle retention, and a customer-managed KMS key.
  - Added an ECR KMS key/alias in `terraform/aws/kms.tf`.
  - Updated `terraform/aws/outputs.tf` to output `ecr_repository_urls` map.
  - Replaced AWS `apply.sh` and `destroy.sh` hardcoded credentials with environment-driven scripts using S3 backend config and native S3 lockfile.
  - Updated AWS `dev`, `staging`, and `prod` tfvars to match the newer private EKS variables.
  - Extended `.gitignore` for Terraform plans, generated lock files, local tfvars, environment files, and local credential JSON artifacts.
  - EKS public API access now defaults to public only for dev. Staging and prod tfvars disable the public endpoint by setting `api_allowed_cidrs = []`; non-dev environments reject `0.0.0.0/0`.
- Static AWS credentials were present in the previous AWS scripts. They have been removed from the working tree, but any exposed real credentials should still be considered compromised and rotated outside this repo.
- Parallel audit findings incorporated:
  - AWS audit: backend/CI contract needed provider-specific S3 backend args; production EKS API could not stay public; future modules should split network, EKS, IAM, KMS, ECR, DNS, and observability.
  - Kubernetes platform audit: current platform is Azure-oriented; AWS needs AWS Load Balancer Controller, ExternalDNS with Cloudflare DNS-only, cert-manager DNS-01, External Secrets Operator, AWS storage classes, declarative provider-neutral bootstrap, and restricted ArgoCD/Keycloak settings.
  - Helm/GitOps audit: application charts need secure defaults, startup probe rendering, frontend probes, service account automount disabled, PDBs, NetworkPolicies, topology spread, rollout fields, immutable image tags, strict CORS, and provider-driven ArgoCD values.
  - CI/supply-chain audit: utilities still contains static Azure credentials; AWS OIDC is missing across pipelines; app image publishing is Azure-specific; Java/frontend quality gates and Trivy/SBOM/IaC/Helm policy checks are missing.
- CI implementation started:
  - `infrastructure/.gitlab-ci.yml` now defaults to `CLOUD_PROVIDER=aws`.
  - AWS CI jobs initialize the S3 backend with bucket/key/region/native lockfile args.
  - AWS CI can assume `AWS_ROLE_ARN` through GitLab OIDC using `GITLAB_OIDC_TOKEN`; static AWS env credentials remain a transitional fallback.
  - Terraform plan artifacts now expire after one week.
- Cross-repo credential cleanup started:
  - `utilities/build.sh` now has no embedded Azure credentials and uses provider-aware AWS ECR / Azure ACR login from environment variables.
  - `kubernetes-infrastructure/terraform/kubernetes/aws_apply.sh` and `aws_destroy.sh` now use ambient AWS identity and configurable S3 backend settings instead of embedded AWS keys.
  - `kubernetes-infrastructure/terraform/kubernetes/azure_apply.sh` and `azure_destroy.sh` now require Azure and GitLab credentials from the environment instead of embedding them.
  - Added `kubernetes-infrastructure/.gitignore` for Terraform/generated credential artifacts.
- Validation:
  - `terraform fmt -recursive` and `terraform validate` passed in `infrastructure/terraform/aws`.
  - Git Bash `bash -n` passed for edited infrastructure, Kubernetes, and utilities shell scripts.
  - Generic `bash` resolves to WSL on this host and failed because no WSL distribution is installed; Git Bash was used for syntax validation.
  - Secret-pattern scan for `kubernetes-infrastructure` and `utilities`, excluding `.terraform`, found no remaining live-looking AWS session key, GitLab PAT, or hardcoded Azure secret patterns.
- Phase 3 implementation started in `kubernetes-infrastructure`:
  - Added AWS Load Balancer Controller, ExternalDNS for Cloudflare DNS-only, External Secrets Operator, Cloudflare DNS-01 ClusterIssuer, and AWS `gp3` StorageClass behind AWS-only conditionals.
  - Ingress-nginx now gets AWS NLB annotations on AWS and snippet annotations are disabled.
  - PostgreSQL in-cluster demo path now uses `gp3` on AWS and retains `managed-csi` elsewhere.
  - Kubernetes Terraform validation passed after these changes.
- Phase 2/3 IAM handoff implemented:
  - Added IRSA roles and policies in `infrastructure/terraform/aws/platform_addon_iam.tf` for AWS Load Balancer Controller and External Secrets Operator.
  - Exposed `aws_load_balancer_controller_role_arn` and `external_secrets_role_arn` outputs from AWS infrastructure.
  - Kubernetes platform now consumes those outputs from AWS remote state when explicit role ARN variables are not provided.
  - No WAF permissions were added.
  - AWS and Kubernetes Terraform validation both passed after this wiring.
- AWS External Secrets implementation started:
  - On AWS, direct app Kubernetes secrets are replaced by ExternalSecret manifests backed by AWS Secrets Manager.
  - Existing Kubernetes secret names are preserved for the application Helm charts.
  - Kubernetes Terraform validation passed after this change.
- ArgoCD platform hardening started:
  - AppProject permissions are no longer wildcarded across every namespace/resource.
  - Local admin is disabled in the ArgoCD Helm values template and OIDC certificate verification is enabled.
  - ArgoCD certificate issuer is now provider-driven through `cluster_issuer`.
  - Kubernetes Terraform validation passed after this change.

## Next Steps
- Rotate any real credentials that were previously committed in AWS, Azure, GitLab, or utility scripts.
- Continue Phase 1 with backend bootstrap documentation and module layout.
- Continue Phase 3 by tightening Keycloak, network policies, and application Helm chart hardening.
