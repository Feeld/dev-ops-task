variable "gke_master_version" {}

resource "google_container_cluster" "primary" {
  name                     = "primary"
  location                 = "europe-west2"
  remove_default_node_pool = true
  initial_node_count       = 1 # per zone in region
  min_master_version       = "${var.gke_master_version}"

  master_auth {
    username = "feeld-master"
    password = "jee0Wah3Thoh9ha1eehoo6OoMie7ethe"

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
