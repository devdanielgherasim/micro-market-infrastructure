# Azure Infrastructure with Terraform

This repository contains Terraform code to deploy an Azure infrastructure with the following components:

- Azure Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS) cluster
- Azure DNS Zone (optional)
- Kubernetes add-ons:
  - NGINX Ingress Controller
  - cert-manager
  - ArgoCD
  - Prometheus
  - Grafana

## Architecture

The infrastructure is designed with a modular approach, following Terraform best practices:

```
terraform/
├── modules/                      # Reusable modules
│   ├── resource_group/           # Azure Resource Group module
│   ├── container_registry/       # Azure Container Registry module
│   ├── kubernetes/               # Azure Kubernetes Service module
│   ├── dns/                      # Azure DNS Zone module
│   └── kubernetes_addons/        # Kubernetes add-ons module
├── tfvars_files/                 # Environment-specific variable files
│   ├── dev.tfvars                # Development environment variables
│   ├── test.tfvars               # Test environment variables
│   └── prod.tfvars               # Production environment variables
├── main.tf                       # Main Terraform configuration
├── variables.tf                  # Variable definitions
├── providers.tf                  # Provider configurations
├── plan.bat                      # Deployment script
└── destroy.bat                   # Destruction script
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>= 1.5.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions
- Service Principal with Contributor access to the Azure subscription

## Infrastructure Components

### Azure Resource Group

A resource group is created to contain all the resources for this project.

### Azure Container Registry (ACR)

An Azure Container Registry is created to store Docker images for the applications that will be deployed to the AKS cluster.

### Azure Kubernetes Service (AKS)

An AKS cluster is created to run the containerized applications. The cluster is configured with:

- System-assigned managed identity
- Auto-scaling (in production environment)
- Role assignment to pull images from ACR

### Azure DNS Zone (Optional)

An Azure DNS Zone can be created to manage DNS records for the services deployed in the AKS cluster.

### Kubernetes Add-ons

The following add-ons are installed on the AKS cluster:

#### NGINX Ingress Controller

The NGINX Ingress Controller provides an entry point for HTTP and HTTPS traffic to the applications running in the cluster.

#### cert-manager

cert-manager is a native Kubernetes certificate management controller that helps with issuing certificates from various sources like Let's Encrypt.

#### ArgoCD

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes that helps automate the deployment and lifecycle management of applications.

#### Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit that collects and stores metrics as time series data.

#### Grafana

Grafana is an open-source platform for monitoring and observability that allows you to query, visualize, and alert on metrics.

## Configuration

The infrastructure can be configured using the following files:

- `variables.tf`: Defines the variables used in the Terraform code
- `tfvars_files/dev.tfvars`: Contains the values for the development environment
- `tfvars_files/test.tfvars`: Contains the values for the test environment
- `tfvars_files/prod.tfvars`: Contains the values for the production environment

### Resource Tagging

All Azure resources are tagged with the following tags:

- `Environment`: The environment name (e.g., Development, Production)
- `Project`: The project name
- `ManagedBy`: Set to "Terraform" to indicate that the resource is managed by Terraform

You can customize these tags by modifying the `tags` variable in the tfvars files.

### Environment-Specific Configurations

The infrastructure is configured differently for development, test, and production environments:

#### Development Environment

- Single-node AKS cluster with basic VM size
- Basic ACR SKU
- Single replica for each Kubernetes component
- Let's Encrypt staging issuer for certificates

#### Test Environment

- Similar to development but can be customized as needed

#### Production Environment

- Multi-node AKS cluster with auto-scaling enabled
- Standard ACR SKU for better performance
- Multiple replicas for each Kubernetes component for high availability
- Let's Encrypt production issuer for valid certificates

## Deployment

### Setting Up Credentials

Before deploying, you need to set up the following environment variables with your Azure credentials:

```bash
# Windows PowerShell
$env:ARM_CLIENT_ID="your-client-id"
$env:ARM_CLIENT_SECRET="your-client-secret"
$env:ARM_TENANT_ID="your-tenant-id"
$env:ARM_SUBSCRIPTION_ID="your-subscription-id"

# Windows Command Prompt
set ARM_CLIENT_ID=your-client-id
set ARM_CLIENT_SECRET=your-client-secret
set ARM_TENANT_ID=your-tenant-id
set ARM_SUBSCRIPTION_ID=your-subscription-id
```

These environment variables are used by the deployment scripts and Terraform to authenticate with Azure.

### Deployment Process

The deployment is done in two phases:

1. Infrastructure deployment: Creates the Azure resources (Resource Group, ACR, AKS)
2. Kubernetes resources deployment: Installs the Kubernetes add-ons (NGINX Ingress, cert-manager, ArgoCD, Prometheus, Grafana)

This two-phase approach ensures that the AKS cluster is fully operational before attempting to install the Kubernetes add-ons.

### Development Environment

To deploy the infrastructure to the development environment, run:

```bash
.\plan.bat
```

or explicitly specify the environment:

```bash
.\plan.bat dev
```

This will:
1. Initialize Terraform
2. Create a plan for the infrastructure deployment
3. Apply the plan after confirmation
4. Optionally deploy the Kubernetes resources after confirmation

### Test Environment

To deploy the infrastructure to the test environment, run:

```bash
.\plan.bat test
```

### Production Environment

To deploy the infrastructure to the production environment, run:

```bash
.\plan.bat prod
```

### Destroying the Infrastructure

To destroy the infrastructure, run:

```bash
.\destroy.bat
```

This will destroy the infrastructure for the development environment. To destroy the test or production environment, run:

```bash
.\destroy.bat test
# or
.\destroy.bat prod
```

For production environment, an additional confirmation is required to prevent accidental destruction.

## Accessing the Services

### NGINX Ingress Controller

After deploying the NGINX Ingress Controller, you can access it using the external IP address assigned to the LoadBalancer service:

```bash
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller
```

### ArgoCD

After deploying ArgoCD, you can access the web UI through the Ingress that was created:

```bash
# Get the Ingress hostname
kubectl get ingress -n argocd
```

When TLS is enabled, you can access ArgoCD securely via HTTPS.

The default username is `admin`. To get the initial password, run:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Grafana

After deploying Grafana, you can access the web UI through the Ingress that was created:

```bash
# Get the Ingress hostname
kubectl get ingress -n monitoring
```

When TLS is enabled, you can access Grafana securely via HTTPS.

The default username is `admin`. To get the initial password, run:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

## Customization

### Adding New Modules

To add a new module:

1. Create a new directory under `modules/`
2. Create the following files:
   - `main.tf`: Define the resources
   - `variables.tf`: Define the input variables
   - `outputs.tf`: Define the output values
3. Update the root `main.tf` to use the new module

### Modifying Existing Modules

To modify an existing module:

1. Update the module files as needed
2. Run `terraform init -upgrade` to ensure the latest module version is used
3. Run the deployment script to apply the changes

## Best Practices

This Terraform code follows these best practices:

- **Modularity**: Code is organized into reusable modules
- **Separation of Concerns**: Each module has a single responsibility
- **Variable Validation**: Input variables are validated where possible
- **Secure Credentials**: Sensitive values are marked as sensitive and not stored in the state file
- **Resource Tagging**: All resources are tagged for better organization and cost tracking
- **Environment Separation**: Different environments use different state files and variable values
- **Dependency Management**: Resources are created in the correct order using dependencies
- **Error Handling**: Deployment scripts include error handling and validation