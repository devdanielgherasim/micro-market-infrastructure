# Azure Infrastructure with NGINX Ingress Controller

This repository contains Terraform code to deploy an Azure infrastructure with the following components:

- Azure Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS) cluster
- NGINX Ingress Controller (via Helm)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>= 1.5.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions

## Infrastructure Components

### Azure Resource Group

A resource group is created to contain all the resources for this project.

### Azure Container Registry (ACR)

An Azure Container Registry is created to store Docker images for the applications that will be deployed to the AKS cluster.

### Azure Kubernetes Service (AKS)

An AKS cluster is created to run the containerized applications.

### NGINX Ingress Controller

The NGINX Ingress Controller is installed on the AKS cluster using Helm. It provides an entry point for HTTP and HTTPS traffic to the applications running in the cluster.

## Configuration

The infrastructure can be configured using the following files:

- `variables.tf`: Defines the variables used in the Terraform code
- `tfvars_files/dev.tfvars`: Contains the values for the development environment
- `tfvars_files/prod.tfvars`: Contains the values for the production environment

## Deployment

### Development Environment

To deploy the infrastructure to the development environment, run:

```bash
.\plan.bat
```

This will initialize Terraform, create a plan, and provide instructions for applying the changes.

### Production Environment

To deploy the infrastructure to the production environment, run:

```bash
.\plan_prod.bat
```

This will initialize Terraform, create a plan, and provide instructions for applying the changes.

## Incremental Deployment

The infrastructure can be deployed incrementally by targeting specific resources:

1. First, deploy the resource group:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=azurerm_resource_group.rg
   ```

2. Then, deploy the AKS cluster:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=azurerm_kubernetes_cluster.k8s
   ```

3. Finally, deploy the NGINX Ingress Controller:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=helm_release.nginx_ingress
   ```

## Accessing the NGINX Ingress Controller

After deploying the NGINX Ingress Controller, you can access it using the external IP address assigned to the LoadBalancer service:

```bash
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller
```

This will display the external IP address that you can use to access your applications through the NGINX Ingress Controller.

## Customizing the NGINX Ingress Controller

The NGINX Ingress Controller can be customized by modifying the Helm release resource in `main.tf`. You can add additional `set` blocks to configure the controller according to your requirements.

For more information on the available configuration options, see the [NGINX Ingress Controller documentation](https://kubernetes.github.io/ingress-nginx/).