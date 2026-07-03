# Security guardrails

## Never commit credentials

All cloud credentials come from environment variables (locally) or GitLab CI variables /
OIDC federation (pipelines). `apply.sh`/`destroy.sh` fail fast when credentials are unset.
`.gitignore` blocks state files, plan artifacts (`tfplan`, `plan.json`), and key material
(`*service-account*.json`, `*-key.json`, `*.pem`, ...). CI runs GitLab Secret Detection on
every pipeline.

## Pre-commit secret scanning (recommended)

Install [gitleaks](https://github.com/gitleaks/gitleaks) and enable it as a pre-commit hook:

```shell
# one-time, in this repo
git config core.hooksPath .githooks
```

`.githooks/pre-commit` runs `gitleaks protect --staged` and rejects commits containing
secret-like content. To scan the whole tree manually:

```shell
gitleaks detect --source .
```

## Incident note (2026-07-03)

Credentials were previously present in this repo (hardcoded Azure SP secret in
`terraform/azure/apply.sh`/`destroy.sh`, a GCP service-account key file, AWS STS
credentials in older commits). All of them were removed from the working tree and
**must be treated as compromised and rotated**; git history was intentionally kept
(rotation-only policy). Do not reuse any credential found in history.
