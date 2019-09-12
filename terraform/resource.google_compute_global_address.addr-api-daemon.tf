resource "google_compute_global_address" "addr-production-api-daemon" {
  provider = "google-beta"
  name = "addr-production-api-daemon"
}

resource "google_compute_global_address" "addr-staging-api-daemon" {
  provider = "google-beta"
  name = "addr-staging-api-daemon"
}

output "addr_addr-production-api-daemon" {
  value = "${google_compute_global_address.addr-production-api-daemon.address}"
}

output "addr_addr-staging-api-daemon" {
  value = "${google_compute_global_address.addr-staging-api-daemon.address}"
}
