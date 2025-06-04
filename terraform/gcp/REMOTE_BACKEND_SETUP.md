# Setting Up Remote Backend for Terraform on Google Cloud

This document provides a step-by-step guide for setting up a remote backend for Terraform on Google Cloud Platform (GCP). Using a remote backend allows for:

- Team collaboration on infrastructure
- State locking to prevent concurrent modifications
- Secure storage of sensitive state information
- State versioning and history

## Manual Steps Required in Google Cloud Console

Before you can use the Terraform scripts in this repository with a remote backend, you need to manually set up the following resources in the Google Cloud Console:

### 1. Create a GCS Bucket

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **Cloud Storage** > **Buckets**
3. Click **CREATE BUCKET**
4. Name your bucket (e.g., `terraform-state-<your-project>`)
5. Choose a location type (Region, Dual-region, or Multi-region)
6. Set the storage class (Standard is recommended for frequently accessed state)
7. Set access control to Fine-grained (recommended)
8. Click **CREATE**

### 2. Configure Bucket Permissions

1. In the bucket details page, go to the **PERMISSIONS** tab
2. Ensure your user account or service account has the following roles:
   - Storage Admin (`roles/storage.admin`)
   - Storage Object Admin (`roles/storage.objectAdmin`)

### 3. Enable Versioning (Optional but Recommended)

1. In the bucket details page, go to the **CONFIGURATION** tab
2. Find "Object Versioning" and click **EDIT**
3. Enable versioning
4. Click **SAVE**

### 4. Create a Service Account for Terraform (if not already done)

1. Navigate to **IAM & Admin** > **Service Accounts**
2. Click **CREATE SERVICE ACCOUNT**
3. Name your service account (e.g., `terraform-admin`)
4. Grant the following roles:
   - Storage Admin (`roles/storage.admin`)
   - Compute Admin (`roles/compute.admin`)
   - Kubernetes Engine Admin (`roles/container.admin`)
   - Service Account User (`roles/iam.serviceAccountUser`)
5. Click **DONE**
6. Create and download a key for this service account (JSON format)

### 5. Enable Required APIs

1. Navigate to **APIs & Services** > **Library**
2. Search for and enable the following APIs if not already enabled:
   - Compute Engine API
   - Kubernetes Engine API
   - Cloud Storage API
   - IAM API
   - Cloud Resource Manager API

## Updating the Scripts

After setting up the GCS bucket and service account, you need to update the `apply.sh` and `destroy.sh` scripts with your specific configuration:

1. Open `apply.sh` and `destroy.sh` in a text editor
2. Update the following lines with your actual values:
   ```bash
   terraform init -backend-config="bucket=YOUR_GCS_BUCKET_NAME" \
                  -backend-config="prefix=terraform/state" \
                  -backend-config="credentials=path/to/your/credentials.json"
   ```
3. Update the project ID and credentials file path:
   ```bash
   terraform apply --var-file=./tfvars_files/dev.tfvars \
                   --var project_id="YOUR_GCP_PROJECT_ID" \
                   --var credentials_file="path/to/your/credentials.json"
   ```

## Using the Scripts

After updating the scripts with your configuration:

1. Make the scripts executable:
   ```bash
   chmod +x apply.sh
   chmod +x destroy.sh
   ```

2. Run the apply script to create the infrastructure:
   ```bash
   ./apply.sh
   ```

3. When you're done, run the destroy script to clean up:
   ```bash
   ./destroy.sh
   ```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure your service account has the necessary permissions.
2. **Bucket Not Found**: Verify the bucket name is correct and the bucket exists.
3. **Invalid Credentials**: Make sure the path to your credentials file is correct.
4. **API Not Enabled**: Ensure all required APIs are enabled in your GCP project.

For more information, see the [Terraform GCS Backend Documentation](https://www.terraform.io/docs/language/settings/backends/gcs.html).