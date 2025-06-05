# Azure Infrastructure with Terraform

This directory contains Terraform configurations for deploying infrastructure on Azure.

## Environment-Specific Remote States

The Terraform configuration in this directory uses environment-specific remote states to isolate different environments (dev, prod, etc.). This is achieved by:

1. Using a generic backend configuration in `providers.tf`:
   ```hcl
   backend "azurerm" {}
   ```

2. Providing environment-specific backend configurations during initialization in the apply and destroy scripts:
   - For development environment (`apply.sh` and `destroy.sh`):
     ```bash
     terraform init \
       -backend-config="resource_group_name=rg-infrastructure" \
       -backend-config="storage_account_name=terraformmicrostate" \
       -backend-config="container_name=tfstate" \
       -backend-config="key=environments/dev/terraform.tfstate"
     ```
   - For production environment (`apply_prod.sh` and `destroy_prod.sh`):
     ```bash
     terraform init \
       -backend-config="resource_group_name=rg-infrastructure" \
       -backend-config="storage_account_name=terraformmicrostate" \
       -backend-config="container_name=tfstate" \
       -backend-config="key=environments/prod/terraform.tfstate"
     ```

This approach allows for:
- Separate state files for different environments
- Independent management of each environment
- Reduced risk of accidental changes to production environment

## Usage

### Development Environment

To deploy to the development environment:

```bash
./apply.sh
```

To destroy resources in the development environment:

```bash
./destroy.sh
```

### Production Environment

To deploy to the production environment:

```bash
./apply_prod.sh
```

To destroy resources in the production environment:

```bash
./destroy_prod.sh
```

## Environment-Specific Variables

Environment-specific variables are defined in the `tfvars_files` directory:
- `dev.tfvars`: Variables for the development environment
- `prod.tfvars`: Variables for the production environment

These files define environment-specific settings such as VM sizes, node counts, and tags.

## Azure Resources

The infrastructure includes the following Azure resources:

- **Azure Container Registry (ACR)**: For storing container images
- **Azure Kubernetes Service (AKS)**: For running containerized applications
- **Resource Group**: For organizing and managing Azure resources

## Authentication

The scripts use Service Principal authentication with the following credentials:
- Client ID
- Client Secret
- Tenant ID
- Subscription ID

These credentials are passed as variables to the Terraform commands in the apply and destroy scripts.