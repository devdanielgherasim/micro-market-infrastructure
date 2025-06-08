# Update Keycloak Hostname Configuration
# This script applies the changes to remove deprecated hostname options in Keycloak

# Set working directory
Set-Location -Path "E:\Master\Disertatie\Sources\infrastructure\terraform\kubernetes"

# Display information about the changes
Write-Host "Updating Keycloak configuration to remove deprecated hostname options..."
Write-Host "The following changes will be made:"
Write-Host "1. Remove 'hostname:v1' from KC_FEATURES"
Write-Host "2. Remove KC_HOSTNAME_STRICT environment variable"
Write-Host "3. Remove KC_HOSTNAME_STRICT_HTTPS environment variable"
Write-Host ""

# Prompt user to continue
$continue = Read-Host -Prompt "Do you want to apply these changes? (y/n)"
if ($continue -ne "y") {
    Write-Host "Operation cancelled by user."
    exit
}

# Apply Keycloak module
Write-Host "`nApplying Keycloak module..."
terraform init
terraform apply -target=helm_release.keycloak -auto-approve

Write-Host "`nKeycloak configuration updated successfully."
Write-Host "Please check the Keycloak logs to verify that the warnings about deprecated hostname options are resolved."
Write-Host "If you still see warnings, you may need to make additional changes to the configuration."