I would like to build end-to-end Terraform that produces a Python Kafka Producer that produces sample data to a Kafka topic based on the Schema Registry via an NGINX proxy between the producer and the kafka cluster running confluent cloud. Use the following context specification.


Architecture
============
Everything should be built using Terraform.
All code should be versioned in the GitHub repo.
All infrastructure and components should be built in Azure.
We should use two separate Azure VNets: 1 for the Producer and 1 for the NGINX proxy.  Confluent Cloud Azure Kafka runs in its own VNet.
The Producer VNet connection should communicate over the public internet via SSL to the NGINX proxy VNet.
The NGINGX VNet should communicate over the public internet the Confluent Cloud Kafka Cluster and Schema Registry.
All connections must use TLS.
Communication flows from the Producer -> NGINX Proxy -> Confluent Cloud all using TLS over the public internet.


Producer
========
Must be written in Python
Must live in its own seperate VNet


NGINX Proxy
===========
Do not use the built-in Kubernetes Ingress Controller.  Instead install a new NGINX container on top of Azure Kubernetes Service, AKS.
Use Kubernetes with services to pull down nginx:latest and run NGINX in a Pod.
NGINX should listen to incoming connections from the Producer VNET on port 8082.
NGINX should connect to Confluent Cloud in Azure via the default bootstrap port 9092.
NGINX must use the TCP stream protocol for TCP data forwarding by using the `ngx_stream_proxy_module` module.
Configure NGINX to pass the TLS connection through without decrypting it (SSL Passthrough).


Environment Variables
======================
Any good practice around environment variables should be used and documented.


Confluent Cloud
===============
Built inside of its own Azure VNet.
Uses the ESSENTIALS package for Governance along with Schema Registry
All components including the Environment, service accounts, API Keys, Topics, and clusters are prefixed with "cjackson-".
This workload runs in a new Environment.
A service account should be used that manages and have access to appropriate Confluent Cloud resources with proper RBAC access such as DeveloperRead,DeveloperWrite if needed for Schema Registry, Kafka Cluster and topics.


Terraform
==========
All Terraform resources and data should be prefixed with "cjackson-".
Terraform code should output all relevant url endpoints links such as load balancer links if available, kafka cluster, nginx urls, schema registry urls, etc. 
All API Keys and secrets when generated should be output to GitHub Secrets and access by the Proucer and other components using GitHub Secrets, which can be visible by GitHub Admins with proper access.


GitHub
=======
GitHub repo is cursor-nginx-proxy
Use common GitHub patterns such as GitHub Secrets for API Keys and Secrets, and passwords.
The repo should maintain a README.md file with deployment documentation, how to run the producer, and general documentation on the repo.
We should also maintain and update a Mermaid architecture diagram viewable in raw Mermaid format but also imported and converted to an Excalidraw drawing and visible in the README.md on GitHub.
Put this very spec plan into GitHub as well.
The README should show examples of terraform commands needed to deploy this workload as well as update the workload.
The README should also show confluent CLI commands to monitor the workload to test, view, and query the environment.
The README should also include example commands of how to monitor or query the NGINX proxy state and data flow.
The README should also include example commands to query the state of the Kubernetes environment.


