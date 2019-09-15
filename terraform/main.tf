# VARIABLES

variable "billing_account_id" {}
variable "organisation_id" {}
variable "kubernetes_version" {}
variable "project_name" {}
variable "project_version" {}
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

resource "google_folder" "project-folder" {
  provider     = "google-beta"
  display_name = "${var.project_name}"
  parent       = "organizations/${var.organisation_id}"
}

resource "google_project" "project" {
  provider            = "google-beta"
  name                = "${var.project_name}-${var.project_version}"
  project_id          = "${var.project_name}-${var.project_version}"
  folder_id           = "${google_folder.project-folder.name}"
  billing_account     = "${var.billing_account_id}"
  auto_create_network = false
}

resource "google_project_service" "bigquery-json" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "bigquery-json.googleapis.com"
}

resource "google_project_service" "bigquerystorage" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "bigquerystorage.googleapis.com"
}

resource "google_project_service" "cloudkms" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "cloudkms.googleapis.com"
}

resource "google_project_service" "compute" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "compute.googleapis.com"
}

resource "google_project_service" "container" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "container.googleapis.com"
}

resource "google_project_service" "containerregistry" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "containerregistry.googleapis.com"
}

resource "google_project_service" "dns" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "dns.googleapis.com"
}

resource "google_project_service" "iam" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "iam.googleapis.com"
}

resource "google_project_service" "iamcredentials" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "iamcredentials.googleapis.com"
}

resource "google_project_service" "oslogin" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "oslogin.googleapis.com"
}

resource "google_project_service" "pubsub" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "pubsub.googleapis.com"
}

resource "google_project_service" "storage-api" {
  provider                   = "google-beta"
  project                    = "${google_project.project.project_id}"
  disable_dependent_services = true
  service                    = "storage-api.googleapis.com"
}

resource "google_bigquery_dataset" "k8s_usage" {
  provider                    = "google-beta"
  project                     = "${google_project.project.name}"
  dataset_id                  = "k8s_usage"
  friendly_name               = "k8s_usage"
  description                 = "k8s usage information"
  location                    = "europe-west2"
  default_table_expiration_ms = 3600000
}

resource "google_kms_key_ring" "k8s-primary" {
  provider = "google-beta"
  project  = "${google_project.project.name}"
  name     = "k8s-primary"
  location = "${var.gcp_region}"
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "k8s-primary-key" {
  provider        = "google-beta"
  name            = "k8s-primary-key"
  key_ring        = "${google_kms_key_ring.k8s-primary.self_link}"
  rotation_period = "100000s"
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "k8s-primary-key-gke-binding" {
  provider      = "google-beta"
  crypto_key_id = "${google_kms_crypto_key.k8s-primary-key.self_link}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${google_project.project.number}@container-engine-robot.iam.gserviceaccount.com",
  ]
}

resource "google_dns_managed_zone" "feeld-env" {
  provider   = "google-beta"
  project    = "${google_project.project.name}"
  dns_name   = "${var.gcp_dns_root}."
  name       = "feeld-env"
  visibility = "public"
}

resource "google_dns_record_set" "production" {
  provider     = "google-beta"
  project      = "${google_project.project.name}"
  name         = "api.${google_dns_managed_zone.feeld-env.dns_name}"
  managed_zone = "${google_dns_managed_zone.feeld-env.name}"
  type         = "A"
  ttl          = 300

  rrdatas = ["${google_compute_global_address.addr-production-api-daemon.address}"]
}

resource "google_dns_record_set" "staging" {
  provider     = "google-beta"
  project      = "${google_project.project.name}"
  name         = "api.staging.${google_dns_managed_zone.feeld-env.dns_name}"
  managed_zone = "${google_dns_managed_zone.feeld-env.name}"
  type         = "A"
  ttl          = 300

  rrdatas = ["${google_compute_global_address.addr-staging-api-daemon.address}"]
}

resource "google_dns_record_set" "egress" {
  provider     = "google-beta"
  project      = "${google_project.project.name}"
  name         = "egress.${google_dns_managed_zone.feeld-env.dns_name}"
  managed_zone = "${google_dns_managed_zone.feeld-env.name}"
  type         = "A"
  ttl          = 300
  rrdatas      = ["${google_compute_address.addr-outbound-nat.address}"]
}

resource "google_compute_global_address" "addr-production-api-daemon" {
  provider = "google-beta"
  project  = "${google_project.project.name}"
  name     = "addr-production-api-daemon"
}

resource "google_compute_global_address" "addr-staging-api-daemon" {
  provider = "google-beta"
  project  = "${google_project.project.name}"
  name     = "addr-staging-api-daemon"
}

resource "google_compute_address" "addr-outbound-nat" {
  provider     = "google-beta"
  project      = "${google_project.project.name}"
  name         = "addr-outbound-nat"
  address_type = "EXTERNAL"
  region       = "${var.gcp_region}"
}

resource "google_compute_network" "k8s-primary-vpc" {
  provider                = "google-beta"
  project                 = "${google_project.project.name}"
  name                    = "k8s-primary-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "k8s-primary-subnet" {
  provider                 = "google-beta"
  project                  = "${google_project.project.name}"
  name                     = "k8s-primary-subnet"
  network                  = "${google_compute_network.k8s-primary-vpc.name}"
  ip_cidr_range            = "10.0.0.0/16"
  region                   = "${var.gcp_region}"
  private_ip_google_access = true
  enable_flow_logs         = true
}

resource "google_compute_router" "k8s-primary-router" {
  provider = "google-beta"
  project  = "${google_project.project.name}"
  name     = "k8s-router"
  region   = "${google_compute_subnetwork.k8s-primary-subnet.region}"
  network  = "${google_compute_network.k8s-primary-vpc.name}"
  bgp {
    asn = 64588
  }
}

resource "google_compute_router_nat" "k8s-primary-nat" {
  provider                           = "google-beta"
  project                            = "${google_project.project.name}"
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
  project                  = "${google_project.project.name}"
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
  resource_usage_export_config {
    enable_network_egress_metering = true
    bigquery_destination {
      dataset_id = "${google_bigquery_dataset.k8s_usage.dataset_id}"
    }
  }
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service    = "logging.googleapis.com/kubernetes"
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  workload_identity_config {
    identity_namespace = "${google_project.project.name}.svc.id.goog"
  }
  database_encryption {
    state    = "ENCRYPTED"
    key_name = "${google_kms_crypto_key.k8s-primary-key.self_link}"
  }
}

resource "google_container_node_pool" "primary" {
  provider   = "google-beta"
  project    = "${google_project.project.name}"
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

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}

# OUTPUTS

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

output "gcp_project" {
  value = "${google_project.project.name}"
}
