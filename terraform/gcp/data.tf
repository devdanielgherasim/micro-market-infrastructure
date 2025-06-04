data "google_client_config" "default" {}

data "google_container_cluster" "this" {
  name     = google_container_cluster.this.name
  location = var.zone
  project  = var.project_id

  depends_on = [google_container_cluster.this]
}
