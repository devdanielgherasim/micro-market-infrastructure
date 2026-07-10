#!/usr/bin/env python3
"""Sync platform-gitops/platform/keycloak-dns/values.yaml's Azure records
from this root's Terraform outputs.

The Container App default FQDN and custom-domain verification ID change when
Azure recreates the Container App Environment. The DNS names themselves are
owned by Terraform too (`keycloak_dns_name` / `keycloak_dns_txt_name`), so this
script reads all four values from `terraform output -json` and rewrites only the
matching target lines in platform-gitops' keycloak-dns values file.

Run from anywhere; paths are resolved relative to this file. Does not commit or
push - review the diff and commit/sync ArgoCD yourself.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

AZURE_ROOT = Path(__file__).resolve().parents[1]
VALUES_FILE = AZURE_ROOT.parents[2] / "platform-gitops" / "platform" / "keycloak-dns" / "values.yaml"


def terraform_outputs() -> dict:
    result = subprocess.run(
        ["terraform", "output", "-json"],
        cwd=AZURE_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def output_value(outputs: dict, name: str) -> str:
    try:
        value = outputs[name]["value"]
    except KeyError as exc:
        raise SystemExit(f"terraform output {name!r} not found - run terraform apply/refresh first") from exc
    if not isinstance(value, str) or not value:
        raise SystemExit(f"terraform output {name!r} must be a non-empty string")
    return value


def replace_target(text: str, dns_name: str, new_value: str) -> str:
    pattern = re.compile(
        rf"(- dnsName: {re.escape(dns_name)}\n(?:.*\n)*?\s+targets:\n\s+- )([^\n#]+)"
    )
    match = pattern.search(text)
    if not match:
        raise SystemExit(f"could not find a targets entry for dnsName {dns_name!r} in {VALUES_FILE}")
    return text[: match.start(2)] + new_value + text[match.end(2):]


def main() -> int:
    outputs = terraform_outputs()
    dns_name = output_value(outputs, "keycloak_dns_name")
    txt_name = output_value(outputs, "keycloak_dns_txt_name")
    hostname = output_value(outputs, "keycloak_default_hostname")
    verification_id = output_value(outputs, "keycloak_custom_domain_verification_id")

    original = VALUES_FILE.read_text()
    updated = replace_target(original, dns_name, hostname)
    updated = replace_target(updated, txt_name, verification_id)

    if updated == original:
        print(f"[sync-keycloak-dns] already up to date ({VALUES_FILE})")
        return 0

    VALUES_FILE.write_text(updated)
    print(f"[sync-keycloak-dns] updated {VALUES_FILE}")
    print(f"  {dns_name} -> {hostname}")
    print(f"  {txt_name} -> {verification_id}")
    print("[sync-keycloak-dns] review the diff, then commit/push platform-gitops and let ArgoCD sync.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
