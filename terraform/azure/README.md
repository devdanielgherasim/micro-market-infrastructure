# Azure Infrastructure Project

This project provisions the core Azure resources required for your Kubernetes workloads.

## Resources Deployed

- Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)
- Role Assignment (AKS to ACR)
- DNS Zone

## Usage

1. Initialize and apply this project first:

   ```sh
   cd azure
   terraform init
   terraform plan -var-file=../tfvars_files/dev.tfvars -out=tfplan
   terraform apply tfplan
   ```

2. Outputs (such as kubeconfig, resource group, etc.) are required by the Kubernetes Addons project.

## Remote State

To enable the Kubernetes project to consume outputs, configure a remote backend (e.g., Azure Storage) in `azure/providers.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<state-rg>"
    storage_account_name = "<stateacct>"
    container_name       = "tfstate"
    key                  = "azure.terraform.tfstate"
  }
}
```

Replace placeholders with your actual values.
