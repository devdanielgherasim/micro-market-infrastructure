$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$cloudRoots = @("azure", "aws", "gcp")

foreach ($cloud in $cloudRoots) {
    $root = Join-Path $repoRoot "terraform/$cloud"
    $providerFile = if ($cloud -eq "gcp") {
        Join-Path $root "main.tf"
    } else {
        Join-Path $root "providers.tf"
    }
    $rolesFile = Join-Path $root "database_roles.tf"

    if (-not (Test-Path $providerFile)) {
        throw "Missing provider file for ${cloud}: $providerFile"
    }
    if (-not (Test-Path $rolesFile)) {
        throw "Missing PostgreSQL role file for ${cloud}: $rolesFile"
    }

    $provider = Get-Content -Raw $providerFile
    $roles = Get-Content -Raw $rolesFile

    if ($provider -notmatch 'source\s*=\s*"cyrilgdn/postgresql"') {
        throw "$cloud does not declare the cyrilgdn/postgresql provider"
    }
    if ($provider -notmatch 'provider\s+"postgresql"') {
        throw "$cloud does not configure the postgresql provider"
    }

    foreach ($role in @("catalog_svc", "orders_svc", "audit_svc")) {
        if ($roles -notmatch [regex]::Escape($role)) {
            throw "$cloud database_roles.tf does not include $role"
        }
    }

    foreach ($resource in @(
        'resource "postgresql_role" "service"',
        'resource "postgresql_schema" "service"',
        'resource "postgresql_grant" "database"',
        'resource "postgresql_grant" "schema"',
        'resource "postgresql_grant" "tables"',
        'resource "postgresql_grant" "sequences"',
        'resource "postgresql_default_privileges" "tables"',
        'resource "postgresql_default_privileges" "sequences"'
    )) {
        if ($roles -notmatch [regex]::Escape($resource)) {
            throw "$cloud database_roles.tf missing $resource"
        }
    }

    if ($roles -notmatch 'search_path\s*=') {
        throw "$cloud database_roles.tf does not set a service-role search_path"
    }

    if ($cloud -eq "azure") {
        $variablesFile = Join-Path $root "variables.tf"
        $variables = Get-Content -Raw $variablesFile

        if ($variables -notmatch 'variable\s+"manage_postgresql_roles"') {
            throw "azure must expose manage_postgresql_roles to keep private PostgreSQL role management opt-in"
        }
        if ($variables -notmatch 'default\s*=\s*false') {
            throw "azure manage_postgresql_roles must default to false because the private PostgreSQL endpoint is not reachable from normal Terraform runners"
        }
        if ($roles -notmatch 'var\.manage_postgresql_roles\s*\?\s*local\.app_db_roles\s*:\s*\{\}') {
            throw "azure PostgreSQL role resources must be gated behind manage_postgresql_roles"
        }
    }
}

Write-Host "PostgreSQL app role Terraform structure is present for azure, aws, and gcp."
