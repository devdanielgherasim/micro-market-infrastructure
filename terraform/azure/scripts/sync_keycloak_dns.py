#!/usr/bin/env python3
"""Sync platform-gitops/platform/keycloak-dns/values.yaml's Azure records
from this root's live Terraform state.

Keycloak's Container App ingress FQDN and custom-domain verification ID
were previously copy-pasted into keycloak-dns/values.yaml by hand, which
went stale on every redeploy (the Container App Environment's random
suffix changes each time it's recreated). This script re-derives both
values directly from `terraform show -json` (a pure local read of the
already-refreshed state - no `terraform apply` needed, since state's
resource attributes are current the moment a plan/apply last ran, even
though the *output* values in outputs.tf were wrong until this was fixed)
and rewrites just those two target lines, leaving the rest of the file
(including its comments) untouched.

Run from anywhere; paths are resolved relative to this file. Does not
commit or push - review the diff and commit/sync ArgoCD yourself.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

AZURE_ROOT = Path(__file__).resolve().parents[1]
VALUES_FILE = AZURE_ROOT.parents[2] / "platform-gitops" / "platform" / "keycloak-dns" / "values.yaml"


def keycloak_container_app_values() -> dict:
    result = subprocess.run(
        ["terraform", "show", "-json"],
        cwd=AZURE_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    state = json.loads(result.stdout)
    for resource in state.get("values", {}).get("root_module", {}).get("resources", []):
        if resource["address"] == "azurerm_container_app.keycloak":
            return resource["values"]
    raise SystemExit("azurerm_container_app.keycloak not found in terraform state - has it been applied?")


def replace_target(text: str, dns_name: str, new_value: str) -> str:
    pattern = re.compile(
        rf"(- dnsName: {re.escape(dns_name)}\n(?:.*\n)*?\s+targets:\n\s+- )([^\n#]+)"
    )
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"could not find a targets entry for dnsName {dns_name!r} in {VALUES_FILE}")
    return text[: match.start(2)] + new_value + text[match.end(2):]


def main() -> int:
    values = keycloak_container_app_values()
    hostname = values["ingress"][0]["fqdn"]
    verification_id = values["custom_domain_verification_id"]

    original = VALUES_FILE.read_text()
    updated = replace_target(original, "auth.danielgherasim.com", hostname)
    updated = replace_target(updated, "asuid.auth.danielgherasim.com", verification_id)

    if updated == original:
        print(f"[sync-keycloak-dns] already up to date ({VALUES_FILE})")
        return 0

    VALUES_FILE.write_text(updated)
    print(f"[sync-keycloak-dns] updated {VALUES_FILE}")
    print(f"  auth.danielgherasim.com      -> {hostname}")
    print(f"  asuid.auth.danielgherasim.com -> {verification_id}")
    print("[sync-keycloak-dns] review the diff, then commit/push platform-gitops and let ArgoCD sync.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
