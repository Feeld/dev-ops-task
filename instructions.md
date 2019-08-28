Use **Terraform** to set up all **GCP** infrastructure necessary to deploy a simple
application to **GKE**.

Then use whatever tools you prefer to deploy the application to the cluster.

The application should consist of 2 http services and a persistent database
(of your choice), all 3 deployed to a k8s cluster.

- **Service 1**: should have 1 end point exposed to the outside world. 
- **Service 2**: should have 1 end point accessible by service 1. 
- **Database**: should be accessible only from service 2. 

Calling the end point on service 1 should result in a row/document
created in the database.

Deploy 2 versions of the app (**production** and **staging**) in the same cluster
making sure that they are fully isolated.

Submit your work as a **PR** to this git repo with all the code necessary to create the
infrastructure and build/deploy the application.

Provide the following commands:
1. creating the GCP infrastructure
2. build and deploy the application to local cluster (for dev purposes)
3. build and deploy the application to GKE

Bonus points:
1. configure a static ip for outgoing traffic from the cluster (a use case
   for this would be to connect to an external service which only allows
   connections from whitelisted ips)
2. restrict outgoing traffic for one of the services to only be able to connect
   to specific external ips.
3. restrict the Service 1 to only allow outbound traffic to Service 2
4. make the cluster master nodes inaccessible from outside the clusters VPC
4. add secrets management
