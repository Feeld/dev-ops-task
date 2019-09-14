
# Minimum Kubernetes master version. Will be automatically upgraded by GCP as necessary.
kubernetes_version = "1.14.3-gke.11"

# GCP project name
project_name = "feeld-daveio"

# GCP region for region-specific resources
gcp_region = "europe-west2"

# Default zone (inside gcp_region)
gcp_zone = "europe-west2-b"

# DNS records will be created under this level
# You will need to add delegation NS records pointing to the nameservers listed in the output gcp_delegation_nameservers
# Don't include the trailing full stop
gcp_dns_root = "feeld.dave.io"

# CIDR ranges allowed to access the Kubernetes master
master_access_list = [
  { desc = "754t-natv4", cidr = "90.155.88.111/32" },
  { desc = "754t-pubv4", cidr = "81.187.62.64/27" },
]
