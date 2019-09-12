resource "google_compute_network" "k8s-primary" {
  provider = "google-beta"
  name = "k8s-primary"
  auto_create_subnetworks = true
}
