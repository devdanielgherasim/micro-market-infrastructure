#!/bin/bash

# Script to destroy the current Keycloak installation using Terraform targeting
echo "Starting Keycloak destruction process..."

# Initialize Terraform to ensure we have access to the state
echo "Initializing Terraform..."
if ! terraform init -backend-config="config.azure.tfbackend"; then
  echo "Error: Terraform initialization failed. Exiting."
  exit 1
fi

# Use Terraform to destroy Keycloak resources
echo "Destroying Keycloak resources using Terraform..."

# Load variables from the dev.tfvars file and Azure credentials
# Adjust these variables as needed for your environment
terraform destroy -auto-approve \
  --var-file=./tfvars_files/dev.tfvars \
  --var cloud_provider="azure" \
  --var client_id="88376f43-c3ee-4be1-bd05-20c20128b666" \
  --var client_secret="YgW8Q~c1koEgr-cvHgSnkCieYtYA2Pr~MFB6dbDu" \
  --var tenant_id="607d63ca-9f36-4ad8-9f71-8b3efc392eb1" \
  --var subscription_id="fa77afbb-f924-48ff-9fa3-5cd94bf4cb57" \
  -target=kubernetes_ingress_v1.ingress_keycloak \
  -target=kubernetes_config_map_v1.keycloak_realm_config \
  -target=helm_release.keycloak \
  -target=kubernetes_secret_v1.keycloak_admin_secret \
  -target=kubernetes_secret_v1.keycloak_postgresql_secret \
  -target=random_password.grafana_oidc_client_secret \
  -target=random_password.keycloak_truststore_password \
  -target=random_password.keycloak_keystore_password \
  -target=random_password.keycloak_admin_password \
  -target=kubernetes_namespace_v1.keycloak

echo "Keycloak destruction process completed."
