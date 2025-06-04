# Google Cloud Platform Infrastructure

This Terraform configuration sets up the Google Cloud Platform (GCP) infrastructure required for the microservices
application. It creates:

1. A Google Kubernetes Engine (GKE) cluster
2. A Google Container Registry (GCR) for storing container images
3. Necessary IAM roles and service accounts

## Prerequisites

Before you can use this Terraform configuration, you need:

1. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured
2. A Google Cloud Platform account with a project
3. [Terraform](https://www.terraform.io/downloads.html) v1.13.0 installed
4. Service account credentials with appropriate permissions

## Configuration

The infrastructure is configured using Terraform variables. You can set these variables in a `.tfvars` file or through
environment variables.

### Required Variables

| Variable           | Description                               |
|--------------------|-------------------------------------------|
| `project_id`       | The Google Cloud project ID               |
| `credentials_file` | Path to the Google Cloud credentials file |

### Optional Variables

| Variable            | Description                             | Default         |
|---------------------|-----------------------------------------|-----------------|
| `region`            | The Google Cloud region                 | `us-central1`   |
| `zone`              | The Google Cloud zone                   | `us-central1-a` |
| `registry_location` | The location for the container registry | `US`            |
| `project_name`      | The name of the project                 | `gcp-infra`     |
| `environment`       | The environment (e.g., dev, prod)       | `dev`           |
| `machine_type`      | The machine type for the GKE nodes      | `e2-standard-2` |
| `node_count`        | The number of nodes in the GKE cluster  | `1`             |
| `disk_size_gb`      | Disk size in GB for GKE nodes          | `50`            |
| `labels`            | Labels to apply to resources            | `{}`            |

## Setting Up Remote Backend

Before using this Terraform configuration, you should set up a Google Cloud Storage (GCS) bucket to store the Terraform
state remotely. This allows for collaboration and prevents state file loss.

### Manual Steps in Google Cloud Console

1. **Create a GCS Bucket**:
    - Go to the [Google Cloud Console](https://console.cloud.google.com/)
    - Navigate to **Cloud Storage** > **Buckets**
    - Click **CREATE BUCKET**
    - Name your bucket (e.g., `terraform-state-<your-project>`)
    - Choose a location type (Region, Dual-region, or Multi-region)
    - Set the storage class (Standard is recommended for frequently accessed state)
    - Set access control to Fine-grained (recommended)
    - Click **CREATE**

2. **Configure Bucket Permissions**:
    - In the bucket details page, go to the **PERMISSIONS** tab
    - Ensure your user account or service account has the following roles:
        - Storage Admin (`roles/storage.admin`)
        - Storage Object Admin (`roles/storage.objectAdmin`)

3. **Enable Versioning** (Optional but recommended):
    - In the bucket details page, go to the **CONFIGURATION** tab
    - Find "Object Versioning" and click **EDIT**
    - Enable versioning
    - Click **SAVE**

4. **Create a Service Account for Terraform** (if not already done):
    - Navigate to **IAM & Admin** > **Service Accounts**
    - Click **CREATE SERVICE ACCOUNT**
    - Name your service account (e.g., `terraform-admin`)
    - Grant the following roles:
        - Storage Admin (`roles/storage.admin`)
        - Compute Admin (`roles/compute.admin`)
        - Kubernetes Engine Admin (`roles/container.admin`)
        - Service Account User (`roles/iam.serviceAccountUser`)
    - Click **DONE**
    - Create and download a key for this service account (JSON format)

5. **Enable Required APIs**:
    - Navigate to **APIs & Services** > **Library**
    - Search for and enable the following APIs if not already enabled:
        - Compute Engine API
        - Kubernetes Engine API
        - Cloud Storage API
        - IAM API
        - Cloud Resource Manager API

### Update Backend Configuration

After creating the GCS bucket, update the backend configuration in the `apply.sh` script with your bucket details:

```bash
terraform init -backend-config="bucket=YOUR_GCS_BUCKET_NAME" \
               -backend-config="prefix=terraform/state" \
               -backend-config="credentials=path/to/your/credentials.json"
```

## Usage

### Setting Up Credentials

Set up your Google Cloud credentials:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/your/credentials.json"
```

### Using the Apply Script

The repository includes an `apply.sh` script that initializes Terraform with the remote backend and applies the
configuration:

```bash
# Make the script executable
chmod +x apply.sh

# Edit the script to update your GCS bucket and project details
# Then run it
./apply.sh
```

### Manual Initialization

If you prefer to initialize Terraform manually:

### Planning the Deployment

Plan the deployment to see what resources will be created:

```bash
terraform plan -var-file="tfvars_files/dev.tfvars"
```

### Applying the Configuration

Apply the configuration to create the resources:

```bash
terraform apply -var-file="tfvars_files/dev.tfvars"
```

### Destroying the Resources

When you're done, you can destroy the resources:

```bash
terraform destroy -var-file="tfvars_files/dev.tfvars"
```

## Outputs

| Output                   | Description                                          |
|--------------------------|------------------------------------------------------|
| `kubeconfig_path`        | Path to the kubeconfig file for the GKE cluster      |
| `cluster_name`           | The name of the GKE cluster                          |
| `cluster_endpoint`       | The endpoint for the GKE cluster                     |
| `container_registry_url` | The URL of the Google Container Registry             |
| `project_id`             | The Google Cloud project ID                          |
| `region`                 | The Google Cloud region where resources are deployed |

## Integration with Kubernetes Configuration

This infrastructure is designed to work with the Kubernetes Terraform configuration in the `../kubernetes` directory.
After applying this configuration, you can use the outputs to configure the Kubernetes resources.

To use this infrastructure with the Kubernetes configuration, set the `cloud_provider` variable to `gcp` in the
Kubernetes configuration:

```hcl
cloud_provider = "gcp"
```

## Troubleshooting

### Common Issues

1. **Credentials**: Ensure your credentials have the necessary permissions.
2. **Project ID**: Make sure the project ID is correct and the project exists.
3. **Quotas**: Check that you have sufficient quotas in your GCP project for the resources being created.
4. **API Enablement**: Ensure the necessary APIs are enabled in your GCP project:
    - Kubernetes Engine API
    - Container Registry API
    - IAM API

For more information, see the [Google Cloud documentation](https://cloud.google.com/docs).
