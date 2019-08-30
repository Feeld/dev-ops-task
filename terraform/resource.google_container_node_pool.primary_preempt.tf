
resource "google_container_node_pool" "primary_preempt" {
  name       = "primary-pool-0"
  location   = "europe-west2"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 1 # per zone in region
  version    = "${google_container_cluster.primary.master_version}"

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
