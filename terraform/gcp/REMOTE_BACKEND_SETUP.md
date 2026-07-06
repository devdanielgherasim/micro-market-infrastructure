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

### 4. Configure Identity for Terraform

Use user application-default credentials for local runs, or GitLab Workload Identity Federation for CI. Do not create or download long-lived service-account JSON keys.

For a local operator identity, grant the following roles as needed:
   - Storage Admin (`roles/storage.admin`)
   - Compute Admin (`roles/compute.admin`)
   - Kubernetes Engine Admin (`roles/container.admin`)
   - Service Account User (`roles/iam.serviceAccountUser`)
   - Service Account Admin (`roles/iam.serviceAccountAdmin`)
   - Secret Manager Admin (`roles/secretmanager.admin`)

Then authenticate locally:

```bash
gcloud auth application-default login
```

### 5. Enable Required APIs

1. Navigate to **APIs & Services** > **Library**
2. Search for and enable the following APIs if not already enabled:
   - Compute Engine API
   - Kubernetes Engine API
   - Cloud Storage API
   - IAM API
   - Cloud Resource Manager API

## Updating the Backend

After setting up the GCS bucket, initialize Terraform with your backend bucket and prefix:

```bash
terraform init \
  -backend-config="bucket=YOUR_GCS_BUCKET_NAME" \
  -backend-config="prefix=terraform/environments/${WORKSPACE}/state"
```

The local `apply.sh` and `destroy.sh` scripts use `GCP_TF_STATE_BUCKET` and
`GCP_TF_STATE_PREFIX` if set. By default they use bucket
`terraformmicroservicesstate` and prefix `terraform/environments/${WORKSPACE}/state`,
so dev/staging/prod do not all share a hardcoded `dev` backend prefix.

The provider uses Google application-default credentials from `gcloud auth application-default login` locally, or `GOOGLE_APPLICATION_CREDENTIALS` pointing at a Workload Identity Federation credential configuration in CI.

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
3. **Invalid Credentials**: Re-run `gcloud auth application-default login` locally, or check the GitLab Workload Identity Federation provider and service account variables in CI.
4. **API Not Enabled**: Ensure all required APIs are enabled in your GCP project.

For more information, see the [Terraform GCS Backend Documentation](https://www.terraform.io/docs/language/settings/backends/gcs.html).
