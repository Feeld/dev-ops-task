# Feeld DevOps recruitment task

  ---

## Simplified overview

```mermaid
graph TD
    internet[fa:fa-cloud Internet]
    lb[fa:fa-map-signs Ingress LB]
    subgraph
        apid[fa:fa-cog API daemon]
        apir[fa:fa-compass API Redis]
        apip[fa:fa-database API PostgreSQL]
    end
    subgraph
        dbd[fa:fa-cog Database daemon]
        dbp[fa:fa-database Database PostgreSQL]
    end
    internet -- 80/tcp --> lb
    internet -- 443/tcp --> lb
    lb -- 3000/tcp --> apid
    apid -- 6379/tcp --> apir
    apid -- 5432/tcp --> apip
    apid -- 3001/tcp --> dbd
    dbd -- 5432/tcp --> dbp
```

  ---

## Components

### Ingress LB

*Ingress*. GCP-managed ingress resource. Listens for plaintext and encrypted HTTP, and forwards plaintext requests to the **API daemon**.

### API daemon

*Deployment*. Accepts requests via HTTP, then asynchronously delivers them via HTTP to the **database daemon**. Keeps logs of delivery events and retries failed deliveries automatically.

### API Redis

*StatefulSet*. Used by Resque on the **API daemon** to handle asynchronous job queuing.

### API PostgreSQL

*StatefulSet*. Provides a backing store for the **API daemon** ORM.

### Database daemon

*Deployment*. Accepts requests via HTTP from the **API daemon** and stores them in the **database PostgreSQL** database.

### Database PostgreSQL

*StatefulSet*. Provides a backing store for the **database daemon** ORM and functions as the authoritative storage for received messages.

  ---

## Deliverable tasks

### Create the GCP infrastructure

Terraform is set up to use the `local` backend as this is a toy environment. In any production situation a remote state backend would be very important. During development I used Hashicorp's free Terraform Cloud offering, which worked well.

In this case I used a single file to store all Terraform objects. This environment is just small enough to keep it from getting unwieldy, but anything bigger would benefit from a split configuration.

1. Ensure your user account has the "Folder Creator" role in IAM. This is not given by default, even to account owners.
1. Ensure you have the `gcloud` command-line tool installed and logged in.
2. Edit `terraform/main.auto.tfvars` and configure things to your preference.
3. `bin/deploy deps`
4. `bin/deploy terraform`

### Build and deploy the application to GKE

Note that in this toy environment the application will always be built and pushed tagged as version `1`. If you want to build a different version tag, either build manually or edit the `DAEMON_VERSION` variable at the top of the `bin/deploy` script, and then the Kubernetes YAML to match.

1. Ensure you have `kubectl` installed.
2. Edit `kubernetes/yaml/resources/api-daemon/api-daemon.yml` and `kubernetes/yaml/resources/db-daemon/db-daemon.yml`, changing `spec.template.spec.containers[0].image` to reflect your GCP project name. In production this would be better achieved using Kustomize or similar.
3. Fetch the GKE credentials for the Terraform-created cluster using `gcloud beta container clusters get-credentials primary --region europe-west2` (change the region if necessary).
4. Ensure that `kubectl config current-context` shows the cluster you want to deploy to. If not, something like `kubectl config use-context gke_feeld-daveio_europe-west2_primary` is what you're after. Again, edit the region portion if necessary.
5. `gcloud auth configure-docker`
6. `bin/deploy all`

### Build and deploy the application to a local cluster

These instructions assume you'll be using `minikube`, which is the easiest way to spin up a Kubernetes environment. It also has a built-in Docker daemon, so you won't have to worry about configuring access to GCR.

1. Ensure you have `kubectl` installed.
2. `minikube start`. This will create a `minikube` context in your `kubectl` config and spin up the VM.
3. `kubectl config use-context minikube`
4. `eval $(minikube docker-env)`
5. `bin/deploy deps`
6. `bin/deploy build`
7. `bin/deploy kubernetes`

  ---

## Bonus points

### configure a static ip for outgoing traffic from the cluster (a use case for this would be to connect to an external service which only allows connections from whitelisted ips)

This was achieved in Terraform by configuring a Cloud Router for the cluster VPC and associating it with a reserved external IP.

### restrict outgoing traffic for one of the services to only be able to connect to specific external ips

This can be seen in `kubernetes/yaml/resources/db-daemon/db-daemon.yml` at path `spec.egress[1]`, using an egress policy with an ipBlock parameter.

### restrict the Service 1 to only allow outbound traffic to Service 2

This can be seen in `kubernetes/yaml/resources/db-daemon/api-daemon.yml` at path `spec.egress[2]` along with the other dependencies for the API daemon.

### make the cluster master nodes inaccessible from outside the clusters VPC

This was achieved in Terraform by enabling private master nodes. Some external access from specific ranges is permitted, but external access can be removed entirely by setting `enable_private_endpoint` to `true` with an empty `master_authorized_networks_config` block. This would be feasible if, for example, the development environment had a VPN into the VPC itself.

### add secrets management

The first step of this was to enable encryption for etcd to avoid plaintext storage. This was done using GCP's key management, which transparently encrypts and decrypts secret material. Following that, all secrets were migrated into a single YAML file at the root of the Kubernetes tree - `kubernetes/yaml/resources/secrets.yml` - which was then encrypted using Keybase by encrypting to a Team. The same was done with `teraform/main.auto.tfvars` which contains other sensitive data.

I have included the plaintext version of `secrets.yml` along with an example file for `main.auto.tfvars` to allow you to test the setup without having to be added to the Keybase Team.  If you would like me to add you, let me know your username(s) and I'll add you to the `dave_sandbox` team I use for testing stuff.

This approach is not ideal and was mainly adopted to do *something* to secure sensitive material without extending the duration of this task. Ideally something more formal and integrated would be adopted, for example Hashicorp Vault, which includes deep integration with both Kubernetes and Terraform along with better options for data at rest.
