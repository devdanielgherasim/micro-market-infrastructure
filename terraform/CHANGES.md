# Changes to Fix ClusterIssuer Creation Error

## Issue Description

The following error was occurring during Terraform apply:

```
Error: API did not recognize GroupVersionKind from manifest (CRD may not be installed)
  with module.kubernetes_addons[0].kubernetes_manifest.cluster_issuer[0],
  on modules\kubernetes_addons\main.tf line 103, in resource "kubernetes_manifest" "cluster_issuer":
 103: resource "kubernetes_manifest" "cluster_issuer" {
no matches for kind "ClusterIssuer" in group "cert-manager.io"
```

This error indicates that Terraform is trying to create a Kubernetes resource of kind "ClusterIssuer" in the API group "cert-manager.io", but the Kubernetes API server doesn't recognize this resource type. This typically happens when the Custom Resource Definition (CRD) for the resource hasn't been installed yet or hasn't been fully registered with the API server.

## Root Cause

The issue occurred because:

1. The cert-manager Helm chart is installed with `installCRDs` set to true, which installs the necessary CRDs for cert-manager.
2. However, there's a timing issue where Terraform tries to create the ClusterIssuer resource before the CRDs are fully registered with the Kubernetes API server.
3. Even though we have a `terraform_data` resource and a `time_sleep` resource to create a dependency chain and wait for the CRDs to be registered, the CRDs might still not be fully registered when Terraform tries to create the ClusterIssuer resource.

## Solution

The solution involves:

1. Increasing the wait time in the `time_sleep` resource from 60 seconds to 180 seconds to allow more time for the CRDs to be fully registered with the Kubernetes API server.
2. Understanding that this is a known limitation when working with Kubernetes CRDs, and the error might still occur during the first apply.

### Changes Made

1. Updated the `time_sleep` resource in `modules/kubernetes_addons/main.tf`:
   ```terraform
   # Additional wait time for cert-manager CRDs to be fully registered with the API server
   resource "time_sleep" "wait_for_cert_manager_crds_registration" {
     count = var.install_cert_manager ? 1 : 0

     depends_on = [
       terraform_data.cert_manager_crds_ready
     ]
     create_duration = "180s"  # Increased from 60s to 180s
   }
   ```

## Expected Behavior

Even with the increased wait time, the error might still occur during the first apply. This is expected behavior when working with Kubernetes CRDs, as there's often a delay between when the CRDs are created and when they're fully available for use.

If the error occurs during the first apply, you can:

1. Wait a few minutes for the CRDs to be fully registered with the Kubernetes API server.
2. Run the `plan.bat` script again to apply the changes.

On subsequent applies, the error should not occur as the CRDs will already be fully registered with the Kubernetes API server.

## Conclusion

This issue is a known limitation when working with Kubernetes CRDs, and the error might still occur during the first apply despite the increased wait time. The solution is to understand that this is expected behavior and to run the `plan.bat` script again after waiting a few minutes for the CRDs to be fully registered.