$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$checkovConfig = Get-Content -Raw (Join-Path $repoRoot ".checkov.yaml")
$workflow = Get-Content -Raw (Join-Path $repoRoot ".github/workflows/ci.yml")

$requiredCheckovSkips = @(
    "CKV_AWS_339",
    "CKV_AWS_118",
    "CKV_AWS_157",
    "CKV_AWS_353",
    "CKV_AZURE_136",
    "CKV_GCP_6",
    "CKV_GCP_79",
    "CKV2_AZURE_57",
    "CKV2_AZURE_31",
    "CKV2_AWS_30"
)

foreach ($id in $requiredCheckovSkips) {
    if ($checkovConfig -notmatch "(?m)^\s*-\s+$([regex]::Escape($id))\s*$") {
        throw ".checkov.yaml does not triage $id"
    }
}

if ($workflow -match '\$\{\{\s*inputs\.') {
    throw ".github/workflows/ci.yml still uses direct inputs.* expressions"
}

Write-Host "CI Checkov triage and GitHub input expressions are covered."
