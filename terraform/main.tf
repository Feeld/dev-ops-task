# VARIABLES

variable "kubernetes_version" {}

# GLOBAL

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "feeld-recruitment-daveio"
    # terraform cloud token in .terraformrc
    workspaces {
      prefix = "feeld-"
    }
  }
}

# PROVIDERS

provider "google-beta" {
  version = "~> 2.14"
  # credentials = "${file("_gcp-account.json")}"
  project = "feeld-daveio"
  region  = "europe-west2"
  zone    = "europe-west2-b"
}

# RESOURCES

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
  region       = "europe-west2"
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
  region                   = "europe-west2"
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
  region                             = "europe-west2"
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
  location                 = "europe-west2"
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
    cidr_blocks {
      display_name = "754t-aaisp-nat4"
      cidr_block   = "90.155.88.111/32"
    }
    cidr_blocks {
      display_name = "754t-aaisp-public"
      cidr_block   = "81.187.62.64/27"
    }
    cidr_blocks {
      display_name = "754t-aaisp-babylon"
      cidr_block   = "81.187.148.148/32"
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
  location   = "europe-west2"
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
