---
title: Checkov IaC scanning gate for infrastructure + kubernetes-infrastructure
status: completed
created: 2026-07-03
updated: 2026-07-04
---

# Checkov IaC scanning gate (Terraform repos)

## Context

Part of the cross-repo "Professional multi-cloud infrastructure overhaul" (see
`E:\Master\Disertatie\Sources\plans\2026-07-03-multicloud-platform-overhaul.md`,
Phase 9, Task 26 — Terraform half only). A separate agent handles the
`deployment`/`platform-gitops` Helm+kubeconform+checkov-k8s half of Task 26 in
parallel; this plan covers ONLY:

- `infrastructure/.gitlab-ci.yml` + `infrastructure/terraform/**` (aws/azure/gcp roots)
- `kubernetes-infrastructure/.gitlab-ci.yml` + `kubernetes-infrastructure/terraform/kubernetes/**`

No other repos are touched.

Both repos already have a `validate` stage with a job running
`terraform init` + `terraform validate` + `terraform fmt -check -diff`
(`validate_infrastructure` in `infrastructure`, `validate` in
`kubernetes-infrastructure`), plus a `Security/Secret-Detection.gitlab-ci.yml`
include. `plan`/`apply`/`destroy` stages must stay untouched — this task only
adds to `validate`.

Approach: add a **separate `checkov` job** in the `validate` stage of each
repo, using the dedicated `bridgecrew/checkov:latest` Docker image (not
`pip install` inside the existing terraform-images/stable image), scanning
`terraform/` recursively. Gate on HIGH/CRITICAL via checkov's default
non-zero exit on any failed check, `--check` narrowed as needed, and a
per-repo `.checkov.yaml` config file with `skip-check` entries (each with a
`# reason:` comment) for accepted/intentional lab-scope findings only.
Nothing security-critical (public buckets, open mgmt-port ingress, missing
least-privilege IAM, plaintext secrets) gets skipped — those get fixed in TF.

Checkov 3.3.6 installed locally via `pip install checkov` (also verified
Docker 29.5.3 available as a fallback / for CI parity check) to dry-run
findings before writing the CI job and skip config.

This machine has the known Norton loopback-TLS-interception issue documented
in the multicloud plan's Phase 5/7 validation notes — use
`TF_CLI_CONFIG_FILE` pointed at an empty workspace-local rc file if
`terraform validate`/`init` needs to hit provider registries.

## Tasks

- [x] 1. Install checkov locally (`pip install checkov`, v3.3.6) and confirm docker fallback available.
- [x] 2. Run checkov against `infrastructure/terraform/` (all three cloud roots) as-is; capture full finding list. Severities were NOT available locally: checkov's per-check severity metadata is pulled from the Bridgecrew/Prisma Cloud guidelines API (`api0.prismacloud.io`), which fails on this machine with the same TLS-interception `SSLCertVerificationError` documented for `terraform validate` elsewhere in this plan/the multicloud plan — `--bc-api-key` isn't available for this lab project either. Deviation from the original task wording: instead of filtering by severity, every one of the 78 raw findings was triaged individually (see task 4), which is a strictly stronger gate than a HIGH/CRITICAL-only filter would have been.
- [x] 3. Run checkov against `kubernetes-infrastructure/terraform/kubernetes/` as-is; came back clean (2 passed, 0 failed on the `terraform` framework) — this root is intentionally tiny post-Phase-2 (bootstrap-only). One `secrets` framework false positive found separately (`CKV_SECRET_6` on a Kubernetes Secret *name* reference in `configs/kube-prometheus_config.yaml`, not a real credential).
- [x] 4. Triaged all 78 `infrastructure` findings individually: 16 fixed directly in Terraform, 1 fixed via a resource-scoped inline `#checkov:skip=CKV_AWS_355` comment (AWS's own official IAM policy document, wildcards required), 61 accepted as documented lab-scope skips in `.checkov.yaml` with individual reasons. Nothing security-critical (public buckets, open mgmt-port SGs to 0.0.0.0/0 outside the existing dev-only guard, missing least-privilege IAM, plaintext secrets) was skipped — see final report for the full list.
- [x] 5. Applied Terraform fixes (both repos) - see files-changed list in final report/commit message equivalent below.
- [x] 6. Wrote `infrastructure/.checkov.yaml` (61 skip-check entries, each commented).
- [x] 7. Wrote `kubernetes-infrastructure/.checkov.yaml` (empty skip-check list — repo is clean; documents the pattern for future findings).
- [x] 8. Added `checkov` job to `validate` stage in `infrastructure/.gitlab-ci.yml` (`bridgecrew/checkov:latest`, `entrypoint: [""]`, `checkov -d terraform/ --config-file .checkov.yaml --compact --quiet`). `plan_infrastructure`/`apply_infrastructure`/`destroy_infrastructure` untouched. Also fixed a pre-existing (not introduced by this task, but blocking the mandated YAML-syntax verification) YAML block-scalar bug in the same file's GCP OIDC credential heredoc (`<<EOF ... EOF` with the closing `EOF` at column 1, which prematurely terminates the enclosing `|` literal block per the YAML spec) by replacing the heredoc with an indentation-safe `printf`.
- [x] 9. Added equivalent `checkov` job to `validate` stage in `kubernetes-infrastructure/.gitlab-ci.yml`. `plan`/`apply`/`destroy` untouched.
- [x] 10. Re-ran checkov locally against both repos with `--config-file .checkov.yaml` post-fix: `infrastructure` 247 passed / 0 failed / 2 skipped (the two inline skips); `kubernetes-infrastructure` 2 passed / 0 failed, secrets scan clean.
- [x] 11. Verified: `terraform fmt -check` passed on all 4 roots (aws/azure/gcp/kubernetes) with zero diff. `terraform validate` is BLOCKED on this machine by the pre-existing, previously-documented Norton loopback-TLS-interception issue (`Plugin did not respond` / `GetProviderSchema` failures on every provider, every root, reproducible/consistent, `TF_CLI_CONFIG_FILE` workaround does not help this particular failure mode) - CI is unaffected per the same prior documentation. `git diff --check` clean (exit 0) in both repos. YAML syntax valid (PyYAML `safe_load`) on both modified `.gitlab-ci.yml` files after the heredoc fix.
- [x] 12. Final report delivered to the coordinator with before/after counts, fixed-vs-skipped rationale, exact commands, and scope confirmation.

## Resume notes

All tasks complete. Nothing outstanding for this plan. If a future checkov
run on either repo surfaces a new finding, triage it the same way: fix in
Terraform if it's a real gap, or add a `skip-check` entry to the relevant
`.checkov.yaml` with a `#` reason comment (or a resource-scoped inline
`#checkov:skip=` comment if the check ID must keep applying to other
resources in the same repo).

## Verification

- Checkov run locally against both repos, before/after finding counts reported: `infrastructure` 78 → 0 failed (247 passed, 2 inline-skipped); `kubernetes-infrastructure` 1 → 0 failed (2 passed, secrets scan clean).
- `terraform fmt -check` passes on infrastructure's aws/azure/gcp roots and kubernetes-infrastructure's kubernetes root (all 4, zero diff). `terraform validate` is blocked machine-wide by the pre-existing Norton TLS-interception issue (documented in the parent multicloud plan); not caused by or specific to this task's changes, CI unaffected.
- `git diff --check` clean (exit 0) in both repos.
- YAML syntax valid on both modified `.gitlab-ci.yml` files (confirmed with PyYAML after fixing a pre-existing heredoc/block-scalar bug in `infrastructure/.gitlab-ci.yml`).
- Confirmed via this session's own tool-call history (no Edit/Write ever issued outside `infrastructure/` and `kubernetes-infrastructure/`) that `deployment`, `platform-gitops`, `utilities`, `catalog`, `orders`, `audit`, `micro-market-frontend` were not touched.
