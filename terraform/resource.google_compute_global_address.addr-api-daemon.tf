resource "google_compute_global_address" "addr-api-daemon" {
  name = "addr-api-daemon"
}

output "addr_addr-api-daemon" {
  value = "${google_compute_global_address.addr-api-daemon.address}"
}
