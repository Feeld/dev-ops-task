variable "gke_master_version" {}

resource "google_container_cluster" "primary" {
  provider                 = "google-beta"
  name                     = "primary"
  location                 = "europe-west2"
  network                  = "${google_compute_network.k8s-primary.name}"
  remove_default_node_pool = true
  initial_node_count       = 1 # per zone in region
  min_master_version       = "${var.gke_master_version}"
  addons_config {
    # istio_config {
    #   disabled = false
    #   auth = "AUTH_MUTUAL_TLS"
    # }
    network_policy_config {
      disabled = false
    }
  }
  network_policy {
    enabled = true
  }
  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

output "client_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}

output "kubernetes_endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}
