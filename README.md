# Microservices Infrastructure Repository

This repository contains the infrastructure configuration for deploying microservices using Terraform and ArgoCD.

## Repository Structure

```
/
├── terraform/                  # Terraform configuration for infrastructure provisioning
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Terraform variables
│   ├── providers.tf            # Provider configuration
│   ├── tfvars_files/           # Environment-specific variable values
│   │   ├── dev.tfvars          # Development environment variables
│   │   └── prod.tfvars         # Production environment variables
│   └── README.md               # Terraform documentation
└── argocd/                     # ArgoCD configuration
    ├── README.md               # ArgoCD documentation
    ├── projects/               # ArgoCD Project configurations
    │   ├── dev.yaml            # Development project
    │   ├── staging.yaml        # Staging project
    │   └── prod.yaml           # Production project
    ├── applicationset/         # ApplicationSet configurations
    │   └── microservices-appset.yaml  # ApplicationSet for all microservices
    └── applications/           # Individual Application configurations
        └── sample-app.yaml     # Sample application configuration
```

## Setup Process

### 1. Infrastructure Provisioning

Use Terraform to provision the infrastructure:

```bash
cd terraform
# For development environment
terraform init
terraform plan -var-file=tfvars_files/dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan

# For production environment
terraform init
terraform plan -var-file=tfvars_files/prod.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

### 2. ArgoCD Configuration

After the infrastructure is provisioned, configure ArgoCD:

```bash
# Get kubeconfig for the AKS cluster
az aks get-credentials --resource-group rg-microservices1691715-<environment> --name k8s-microservices1691715-<environment>

# Apply ArgoCD configurations
kubectl apply -f argocd/projects/
kubectl apply -f argocd/applicationset/
```

## Microservices Deployment

The microservices are deployed from the GitLab repository: https://gitlab.com/microservices1691715/deployment

Each microservice follows this structure:
- `environments/` - Environment-specific values files
  - `dev-values.yaml`
  - `staging-values.yaml`
  - `prod-values.yaml`
- `templates/` - Kubernetes manifest templates
  - `deployment.yaml`
  - `hpa.yaml`
  - `ingress.yaml`
  - `service.yaml`
  - `serviceaccount.yaml`
- `values.yaml` - Default values
- `Chart.yaml` - Helm chart metadata

ArgoCD automatically discovers all Helm charts in the repository and deploys them to the appropriate environments based on the ApplicationSet configuration.

## Accessing Services

- ArgoCD UI: https://argocd.k8s-microservices1691715-<environment>.westeurope.azmk8s.io
- Grafana: https://grafana.k8s-microservices1691715-<environment>.westeurope.azmk8s.io