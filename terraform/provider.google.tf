provider "google-beta" {
  version     = "~> 2.14"
  credentials = "${file("_gcp-account.json")}"
  project     = "feeld-daveio"
  region      = "europe-west2"
  zone        = "europe-west2-b"
}
