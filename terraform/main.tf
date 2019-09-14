# VARIABLES

variable "kubernetes_version" {}
variable "project_name" {}
variable "gcp_region" {}
variable "gcp_zone" {}
variable "gcp_dns_root" {}
variable "master_access_list" {}

# GLOBAL

terraform {
  backend "local" {
    path = ".terraform/terraform.tfstate"
  }
}

# PROVIDERS

provider "google-beta" {
  version = "~> 2.14"
  project = "${var.project_name}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}

# RESOURCES

resource "google_dns_managed_zone" "feeld-env" {
  provider   = "google-beta"
  dns_name   = "${var.gcp_dns_root}."
  name       = "feeld-env"
  visibility = "public"
}

resource "google_dns_record_set" "production" {
  provider     = "google-beta"
  name         = "api.${google_dns_managed_zone.feeld-env.dns_name}"
  managed_zone = "${google_dns_managed_zone.feeld-env.name}"
  type         = "A"
  ttl          = 300

  rrdatas = ["${google_compute_global_address.addr-production-api-daemon.address}"]
}

resource "google_dns_record_set" "staging" {
  provider     = "google-beta"
  name         = "api.staging.${google_dns_managed_zone.feeld-env.dns_name}"
  managed_zone = "${google_dns_managed_zone.feeld-env.name}"
  type         = "A"
  ttl          = 300

  rrdatas = ["${google_compute_global_address.addr-staging-api-daemon.address}"]
}

resource "google_dns_record_set" "egress" {
  provider     = "google-beta"
  name         = "egress.${google_dns_managed_zone.feeld-env.dns_name}"
  managed_zone = "${google_dns_managed_zone.feeld-env.name}"
  type         = "A"
  ttl          = 300

  rrdatas = ["${google_compute_address.addr-outbound-nat.address}"]
}

resource "google_compute_global_address" "addr-production-api-daemon" {
  provider = "google-beta"
  name     = "addr-production-api-daemon"
}

resource "google_compute_global_address" "addr-staging-api-daemon" {
  provider = "google-beta"
  name     = "addr-staging-api-daemon"
}

resource "google_compute_address" "addr-outbound-nat" {
  provider     = "google-beta"
  name         = "addr-outbound-nat"
  address_type = "EXTERNAL"
  region       = "${var.gcp_region}"
}

resource "google_compute_network" "k8s-primary-vpc" {
  provider                = "google-beta"
  name                    = "k8s-primary-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k8s-primary-subnet" {
  provider                 = "google-beta"
  name                     = "k8s-primary-subnet"
  network                  = "${google_compute_network.k8s-primary-vpc.name}"
  ip_cidr_range            = "10.0.0.0/16"
  region                   = "${var.gcp_region}"
  private_ip_google_access = true
  enable_flow_logs         = true
}

resource "google_compute_router" "k8s-primary-router" {
  provider = "google-beta"
  name     = "k8s-router"
  region   = "${google_compute_subnetwork.k8s-primary-subnet.region}"
  network  = "${google_compute_network.k8s-primary-vpc.name}"
  bgp {
    asn = 64588
  }
}

resource "google_compute_router_nat" "k8s-primary-nat" {
  provider                           = "google-beta"
  name                               = "k8s-primary-nat"
  router                             = "${google_compute_router.k8s-primary-router.name}"
  region                             = "${var.gcp_region}"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = ["${google_compute_address.addr-outbound-nat.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    filter = "ALL"
    enable = true
  }
}

resource "google_container_cluster" "primary" {
  provider                 = "google-beta"
  name                     = "primary"
  location                 = "${var.gcp_region}"
  network                  = "${google_compute_network.k8s-primary-vpc.name}"
  subnetwork               = "${google_compute_subnetwork.k8s-primary-subnet.name}"
  remove_default_node_pool = true
  initial_node_count       = 1 # per zone in region
  min_master_version       = "${var.kubernetes_version}"
  ip_allocation_policy {
    create_subnetwork = false
    subnetwork_name   = "k8s-primary-subnet"
    use_ip_aliases    = true
  }
  addons_config {
    http_load_balancing { disabled = false }
    kubernetes_dashboard { disabled = false }
    horizontal_pod_autoscaling { disabled = false }
    network_policy_config { disabled = false }
  }
  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.1.0/28"
  }
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_access_list
      content {
        display_name = cidr_blocks.value.desc
        cidr_block   = cidr_blocks.value.cidr
      }
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

resource "google_container_node_pool" "primary" {
  provider   = "google-beta"
  name       = "primary-pool-0"
  location   = "${var.gcp_region}"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 2 # per zone in region
  version    = "${google_container_cluster.primary.min_master_version}"

  management {
    auto_repair  = true
    auto_upgrade = true
  }

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

# OUTPUTS

output "cert_cluster-ca-certificate" {
  value = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}

output "cert_gke-client-certificate" {
  value = "${google_container_cluster.primary.master_auth.0.client_certificate}"
}

output "key_gke-client-key" {
  value = "${google_container_cluster.primary.master_auth.0.client_key}"
}

output "v4addr_outbound-nat" {
  value = "${google_compute_address.addr-outbound-nat.address}"
}

output "v4addr_gke-endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}

output "v4addr_production-api-daemon" {
  value = "${google_compute_global_address.addr-production-api-daemon.address}"
}

output "v4addr_staging-api-daemon" {
  value = "${google_compute_global_address.addr-staging-api-daemon.address}"
}

output "gcp_delegation_nameservers" {
  value = "${google_dns_managed_zone.feeld-env.name_servers}"
}
