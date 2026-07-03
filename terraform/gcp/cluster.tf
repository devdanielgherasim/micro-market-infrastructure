resource "google_container_cluster" "this" {
  name                     = local.cluster_name
  location                 = var.zone
  project                  = var.project_id
  deletion_protection      = var.deletion_protection
  remove_default_node_pool = true
  initial_node_count       = var.node_count

  networking_mode = "VPC_NATIVE"

  # Required for VPC-native clusters and lets GKE auto-manage the pod/service
  # secondary IP ranges (checkov CKV_GCP_23).
  ip_allocation_policy {}

  # Track GKE's regular release channel for timely patch/security upgrades
  # (checkov CKV_GCP_70).
  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = local.workload_pool
  }

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }

  node_config {
    disk_type = "pd-standard"

    # Force the workload identity metadata concealment path (required for
    # Workload Identity, already enabled above, to be secure) and enable
    # Shielded VM secure boot / integrity monitoring on nodes (checkov
    # CKV_GCP_69 / CKV_GCP_68).
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  resource_labels    = local.common_labels
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.this.name
  location   = var.zone
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type

    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type

    labels = local.common_labels
    tags   = ["gke-node", "${var.project_name}-${var.environment}"]

    # See cluster.tf's default node pool config for rationale (checkov
    # CKV_GCP_69 / CKV_GCP_68) — this is the pool that actually runs
    # workloads.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = var.auto_repair
    auto_upgrade = var.auto_upgrade
  }
}
