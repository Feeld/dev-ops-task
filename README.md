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

1. Ensure you have the `gcloud` command-line tool installed and logged in.
2. Create a project in GCP.
3. Edit `terraform/main.auto.tfvars` and configure things to your preference.
4. `bin/manage deps`
5. `bin/manage terraform`

### Build and deploy the application to GKE

1. Ensure you have `kubectl` installed.
2. Fetch the GKE credentials for the Terraform-created cluster using `gcloud beta container clusters get-credentials primary --region europe-west2` (change the region if necessary).
3. Ensure that `kubectl config current-context` shows the cluster you want to deploy to. If not, something like `kubectl config use-context gke_feeld-daveio_europe-west2_primary` is what you're after. Again, edit the region portion if necessary.
4. `gcloud auth configure-docker`
5. `bin/manage deps`
6. `bin/manage bap`
7. `bin/manage kubernetes`

### Build and deploy the application to a local cluster

These instructions assume you'll be using `minikube`, which is the easiest way to spin up a Kubernetes environment. It also has a built-in Docker daemon, so you won't have to worry about configuring access to GCR.

1. Ensure you have `kubectl` installed.
2. `minikube start`. This will create a `minikube` context in your `kubectl` config and spin up the VM.
3. `kubectl config use-context minikube`
4. `eval $(minikube docker-env)`
5. `bin/manage deps`
6. `bin/manage build`
7. `bin/manage kubernetes`

  ---

## Bonus points

- [x] *configure a static ip for outgoing traffic from the cluster (a use case for this would be to connect to an external service which only allows connections from whitelisted ips)*
- [ ] *restrict outgoing traffic for one of the services to only be able to connect to specific external ips*
- [x] *restrict the Service 1 to only allow outbound traffic to Service 2*
- [x] *make the cluster master nodes inaccessible from outside the clusters VPC*
- [ ] *add secrets management*
