$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$azureRoot = Join-Path $repoRoot "terraform/azure"

$applyScript = Get-Content -Raw (Join-Path $azureRoot "apply.sh")
$destroyScript = Get-Content -Raw (Join-Path $azureRoot "destroy.sh")
$commonScriptPath = Join-Path $azureRoot "scripts/_common.sh"
$commonScript = if (Test-Path $commonScriptPath) { Get-Content -Raw $commonScriptPath } else { "" }
$awsApplyScript = Get-Content -Raw (Join-Path $repoRoot "terraform/aws/apply.sh")
$variables = Get-Content -Raw (Join-Path $azureRoot "variables.tf")
$secrets = Get-Content -Raw (Join-Path $azureRoot "secrets.tf")
$keycloakPaas = Get-Content -Raw (Join-Path $azureRoot "keycloak_paas.tf")
$outputs = Get-Content -Raw (Join-Path $azureRoot "outputs.tf")
$dnsSyncScript = Get-Content -Raw (Join-Path $azureRoot "scripts/sync_keycloak_dns.py")

if (-not (Test-Path $commonScriptPath)) {
    throw "Azure apply/destroy scripts must share bootstrap logic through terraform/azure/scripts/_common.sh"
}

foreach ($script in @{"apply.sh" = $applyScript; "destroy.sh" = $destroyScript}.GetEnumerator()) {
    if ($script.Value -notmatch 'source "\$\{SCRIPT_DIR\}/scripts/_common\.sh"') {
        throw "$($script.Key) must source scripts/_common.sh"
    }
    if ($script.Value -match '--var-file="\./tfvars_files/\$WORKSPACE\.tfvars"') {
        throw "$($script.Key) must use VAR_FILE for terraform plan"
    }
    if ($script.Value -notmatch '--var-file="\$\{VAR_FILE\}"') {
        throw "$($script.Key) must use the shared VAR_FILE for terraform plan"
    }
}

if ($commonScript -notmatch 'VAR_FILE="\./tfvars_files/\$\{WORKSPACE\}\.tfvars"') {
    throw "_common.sh must define VAR_FILE from WORKSPACE"
}
if ($commonScript -notmatch '\[\[ -f "\$\{VAR_FILE\}" \]\] \|\| \{ echo "ERROR: \$\{VAR_FILE\} not found" >&2; exit 1; \}') {
    throw "_common.sh must fail early when the tfvars file is missing"
}

foreach ($forbidden in @("AZURE_LOCATION", "TF_VAR_location", '-var location=')) {
    if ($destroyScript -match [regex]::Escape($forbidden)) {
        throw "destroy.sh must not override location via $forbidden"
    }
}

if (($applyScript | Select-String -Pattern "load_bootstrap_env_defaults" -AllMatches).Matches.Count -ne 0) {
    throw "apply.sh must not duplicate load_bootstrap_env_defaults after extraction"
}
if (($destroyScript | Select-String -Pattern "load_bootstrap_env_defaults" -AllMatches).Matches.Count -ne 0) {
    throw "destroy.sh must not duplicate load_bootstrap_env_defaults after extraction"
}

if ($awsApplyScript -match '-lock=false') {
    throw "terraform/aws/apply.sh must not disable Terraform state locking"
}

if ($variables -notmatch 'variable\s+"dns_domain"') {
    throw "Azure variables.tf must expose dns_domain"
}
if ($secrets -notmatch 'DOMAIN\s*=\s*var\.dns_domain') {
    throw "Azure grafana-oauth secret DOMAIN must use var.dns_domain"
}
if ($keycloakPaas -notmatch 'keycloak_hostname\s*=\s*var\.environment == "prod" \? "auth\.\$\{var\.dns_domain\}" : "auth-\$\{var\.environment\}\.\$\{var\.dns_domain\}"') {
    throw "Azure keycloak hostname must derive from var.dns_domain"
}
if ($outputs -notmatch 'output\s+"keycloak_dns_name"') {
    throw "Azure outputs.tf must expose keycloak_dns_name"
}
if ($outputs -notmatch 'output\s+"keycloak_dns_txt_name"') {
    throw "Azure outputs.tf must expose keycloak_dns_txt_name"
}
if ($dnsSyncScript -match 'auth\.danielgherasim\.com') {
    throw "sync_keycloak_dns.py must not hardcode auth.danielgherasim.com"
}
if ($dnsSyncScript -notmatch '"terraform",\s*"output",\s*"-json"') {
    throw "sync_keycloak_dns.py must read DNS names from Terraform outputs"
}

Write-Host "Azure script hardening invariants are covered."
