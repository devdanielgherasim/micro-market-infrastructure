# Keycloak Hostname Configuration Update

## Issue

Keycloak was showing the following warnings in the logs:

```
2025-06-08 15:01:14,965 WARN  [org.key.com.Profile] (main) Deprecated features enabled: hostname:v1
2025-06-08 15:01:15,061 WARN  [org.key.qua.run.cli.Picocli] (main) The following used options or option values are DEPRECATED and will be removed or their behaviour changed in a future release:
	- hostname-strict
	- hostname-strict-https
	- hostname
```

These warnings indicate that Keycloak is using deprecated configuration options related to hostname settings.

## Solution

The following changes were made to the Keycloak configuration in `keycloak.tf`:

1. Removed `hostname:v1` from the `KC_FEATURES` environment variable
2. Removed the `KC_HOSTNAME_STRICT` environment variable
3. Removed the `KC_HOSTNAME_STRICT_HTTPS` environment variable

The `KC_HOSTNAME` environment variable was kept as it's still needed for basic hostname configuration, but the deprecated options were removed.

## How to Apply the Changes

You can apply these changes by running the provided PowerShell script:

```powershell
.\update_keycloak_hostname_config.ps1
```

This script will:
1. Explain the changes being made
2. Prompt for confirmation before proceeding
3. Apply the Terraform changes to update the Keycloak configuration

## Verification

After applying the changes, check the Keycloak logs to verify that the warnings about deprecated hostname options are no longer present.

If you still see warnings, you may need to make additional changes to the configuration based on the specific warnings you're seeing.

## Additional Information

The hostname-related options in Keycloak are being changed in newer versions. The approach taken here is to remove the deprecated options while keeping the basic hostname configuration.

For more information about Keycloak hostname configuration, refer to the official Keycloak documentation.