# Kubernetes Addons Project

This project provisions Kubernetes resources (NGINX Ingress, Cert Manager, ArgoCD, Prometheus, Grafana) on the AKS cluster deployed by the Azure project.

## Prerequisites

- The Azure infrastructure project must be applied first.
- This project requires outputs from the Azure project (e.g., kubeconfig, resource group, etc.).

## Remote State Data Source Example

Add this to your `kubernetes/main.tf` to read outputs from the Azure project:

```hcl
data "terraform_remote_state" "azure" {
  backend = "azurerm"
  config = {
    resource_group_name  = "<state-rg>"
    storage_account_name = "<stateacct>"
    container_name       = "tfstate"
    key                  = "azure.terraform.tfstate"
  }
}
```

Then use outputs like:

```hcl
kubeconfig = data.terraform_remote_state.azure.outputs.kubeconfig
```

## Usage

1. Initialize and apply this project after the Azure project:

   ```sh
   cd kubernetes
   terraform init
   terraform plan -var-file=../tfvars_files/dev.tfvars -out=tfplan
   terraform apply tfplan
   ```

## Notes

- Ensure your provider is configured to use the AKS kubeconfig from the remote state.
- Adjust variables and backend config as needed for your environment.
