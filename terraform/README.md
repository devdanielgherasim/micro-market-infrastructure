# Azure Infrastructure with NGINX Ingress Controller, cert-manager, ArgoCD, Prometheus, and Grafana

This repository contains Terraform code to deploy an Azure infrastructure with the following components:

- Azure Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS) cluster
- NGINX Ingress Controller (via Helm)
- cert-manager (via Helm)
- ArgoCD (via Helm)
- Prometheus (via Helm)
- Grafana (via Helm)

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

### cert-manager

cert-manager is installed on the AKS cluster using Helm. It is a native Kubernetes certificate management controller that helps with issuing certificates from various sources like Let's Encrypt, HashiCorp Vault, Venafi, or a simple signing key pair. It ensures certificates are valid and up-to-date, and attempts to renew certificates at a configured time before expiry.

### ArgoCD

ArgoCD is installed on the AKS cluster using Helm. It is a declarative, GitOps continuous delivery tool for Kubernetes that helps automate the deployment and lifecycle management of applications. ArgoCD follows the GitOps pattern where Git repositories are considered the source of truth for defining the desired application state.

### Prometheus

Prometheus is installed on the AKS cluster using Helm. It is an open-source systems monitoring and alerting toolkit that collects and stores metrics as time series data. Prometheus scrapes metrics from instrumented jobs, stores the data, and makes it available for analysis and alerting. It provides a powerful query language (PromQL) to analyze the collected metrics.

### Grafana

Grafana is installed on the AKS cluster using Helm. It is an open-source platform for monitoring and observability that allows you to query, visualize, alert on, and understand your metrics no matter where they are stored. Grafana is pre-configured to use Prometheus as a data source, making it easy to create dashboards to visualize the metrics collected by Prometheus.

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

3. Deploy the NGINX Ingress Controller:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=helm_release.nginx_ingress
   ```

4. Deploy cert-manager:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=helm_release.cert_manager
   ```

5. Deploy ArgoCD:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=helm_release.argocd
   ```

6. Deploy Prometheus:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=helm_release.prometheus
   ```

7. Finally, deploy Grafana:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars --var client_id="YOUR_CLIENT_ID" --var client_secret="YOUR_CLIENT_SECRET" --var tenant_id="YOUR_TENANT_ID" --var subscription_id="YOUR_SUBSCRIPTION_ID" --target=helm_release.grafana
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

## Accessing ArgoCD

After deploying ArgoCD, you can access the web UI through the Ingress that was created:

```bash
# Get the Ingress hostname
kubectl get ingress -n argocd
```

The default username is `admin`. To get the initial password, run:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

You can also use the ArgoCD CLI to interact with ArgoCD. For more information, see the [ArgoCD CLI documentation](https://argo-cd.readthedocs.io/en/stable/cli_installation/).

## Customizing ArgoCD

ArgoCD can be customized by modifying the Helm release resource in `main.tf`. You can add additional `set` blocks to configure ArgoCD according to your requirements.

For more information on the available configuration options, see the [ArgoCD Helm chart documentation](https://github.com/argoproj/argo-helm/tree/master/charts/argo-cd).

## Accessing Prometheus

After deploying Prometheus, you can access the web UI by port-forwarding the Prometheus server service:

```bash
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
```

Then, open your browser and navigate to `http://localhost:9090`.

## Customizing Prometheus

Prometheus can be customized by modifying the Helm release resource in `main.tf`. You can add additional `set` blocks to configure Prometheus according to your requirements.

For more information on the available configuration options, see the [Prometheus Helm chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus).

## Accessing Grafana

After deploying Grafana, you can access the web UI through the Ingress that was created:

```bash
# Get the Ingress hostname
kubectl get ingress -n monitoring
```

Alternatively, you can use port-forwarding:

```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
```

Then, open your browser and navigate to `http://localhost:3000`.

The default username is `admin`. To get the initial password, run:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

## Customizing Grafana

Grafana can be customized by modifying the Helm release resource in `main.tf`. You can add additional `set` blocks to configure Grafana according to your requirements.

For more information on the available configuration options, see the [Grafana Helm chart documentation](https://github.com/grafana/helm-charts/tree/main/charts/grafana).
