# Multi-Cloud Kubernetes Infrastructure

This Terraform configuration sets up a Kubernetes infrastructure that can be deployed to multiple cloud providers. Currently, it supports:

- Microsoft Azure
- Google Cloud Platform (GCP)
- Amazon Web Services (AWS)

## Prerequisites

### Common Requirements
- Terraform v1.13.0
- kubectl
- helm

### Azure Requirements
- Azure CLI
- Azure subscription
- Service Principal with appropriate permissions

### Google Cloud Requirements
- Google Cloud SDK
- Google Cloud project
- Service Account with appropriate permissions

### AWS Requirements
- AWS CLI
- AWS account
- IAM user with appropriate permissions

## Configuration

The infrastructure is configured using Terraform variables. You can set these variables in a `.tfvars` file or through environment variables.

### Common Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cloud_provider` | The cloud provider to use (`azure` or `gcp`) | `azure` |
| `project_name` | The name of the project | `cloud-infra` |
| `environment` | The environment (e.g., dev, prod) | `dev` |
| `cluster_issuer` | The cert-manager cluster issuer | `letsencrypt-production-cluster-issuer` |
| `domain_suffix` | The domain suffix for GCP (not used for Azure) | `nip.io` |

### Azure-Specific Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `client_id` | The Azure AD Application ID | - |
| `client_secret` | The Azure AD Application Secret | - |
| `tenant_id` | The Azure AD Tenant ID | - |
| `subscription_id` | The Azure Subscription ID | - |

### Google Cloud-Specific Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `gcp_project` | The Google Cloud project ID | - |
| `gcp_region` | The Google Cloud region | `us-central1` |
| `gcp_zone` | The Google Cloud zone | `us-central1-a` |
| `gcp_credentials` | The path to the Google Cloud credentials file | - |

### AWS-Specific Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | The AWS region | `us-east-1` |
| `aws_access_key` | The AWS access key | - |
| `aws_secret_key` | The AWS secret key | - |
| `aws_session_token` | The AWS session token | - |

## Usage

### Deploying to Azure

1. Set up your Azure credentials:
   ```bash
   export ARM_CLIENT_ID="your-client-id"
   export ARM_CLIENT_SECRET="your-client-secret"
   export ARM_TENANT_ID="your-tenant-id"
   export ARM_SUBSCRIPTION_ID="your-subscription-id"
   ```

2. Create or update your `.tfvars` file:
   ```hcl
   cloud_provider = "azure"
   project_name   = "your-project-name"
   environment    = "dev"
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Apply the configuration:
   ```bash
   terraform apply -var-file="tfvars_files/dev.tfvars"
   ```

### Deploying to Google Cloud

1. Set up your Google Cloud credentials:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/your/credentials.json"
   ```

2. Create or update your `.tfvars` file:
   ```hcl
   cloud_provider  = "gcp"
   project_name    = "your-project-name"
   environment     = "dev"
   gcp_project     = "your-gcp-project-id"
   gcp_region      = "us-central1"
   gcp_zone        = "us-central1-a"
   domain_suffix   = "nip.io"
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Apply the configuration:
   ```bash
   terraform apply -var-file="tfvars_files/dev.tfvars"
   ```

### Deploying to AWS

1. Set up your AWS credentials:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_SESSION_TOKEN="your-session-token"  # if using temporary credentials
   ```

2. Create or update your `.tfvars` file:
   ```hcl
   cloud_provider = "aws"
   project_name   = "your-project-name"
   environment    = "dev"
   aws_region     = "us-east-1"
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Apply the configuration:
   ```bash
   terraform apply -var-file="tfvars_files/dev.tfvars"
   ```

   Alternatively, you can use the provided script:
   ```bash
   ./aws_apply.sh
   ```

## Components

The infrastructure includes the following components:

- **Kubernetes Cluster**: Managed by the cloud provider (AKS for Azure, GKE for GCP, EKS for AWS)
- **ArgoCD**: Continuous Delivery tool for Kubernetes
- **Cert-Manager**: Certificate management for Kubernetes
- **Nginx Ingress Controller**: Ingress controller for Kubernetes
- **Prometheus & Grafana**: Monitoring and visualization
- **Loki**: Log aggregation and storage, integrated with Grafana for log visualization
- **Promtail**: Log collection agent that sends logs to Loki

## Accessing the Services

After deployment, you can access the services using the following URLs:

- ArgoCD: `https://<project_name>.<region>.<domain>/`
- Grafana: `https://<project_name>.<region>.<domain>/grafana`
  - Metrics: Available in the Prometheus data source
  - Logs: Available in the Loki data source

Where:
- For Azure: `<domain>` is `cloudapp.azure.com`
- For GCP: `<domain>` is the value of `domain_suffix` (default: `nip.io`)
- For AWS: `<domain>` is the EKS cluster endpoint (accessible via `kubectl cluster-info`)

## Troubleshooting

### Common Issues

1. **Provider Configuration**: Ensure you have the correct credentials for your chosen cloud provider.
2. **Kubernetes Connection**: If you can't connect to the Kubernetes cluster, check that your kubeconfig is correctly set up.
3. **Ingress Issues**: If you can't access services via ingress, check that the DNS records are correctly configured.
4. **Logging Issues**: If logs are not appearing in Grafana:
   - Check that the Loki data source is correctly configured in Grafana
   - Verify that Promtail pods are running and collecting logs
   - Check Promtail logs for any connection issues to Loki

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
