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
A service account should be used with RBAC (DeveloperRead, DeveloperWrite) for Schema Registry and for the Kafka cluster and topics. The Kafka cluster is Standard tier so resource-scoped RBAC is used for Kafka; the same service account has an API key for cluster access (produce/consume) and role bindings for topic and Schema Registry access.

Schema Registry (ESSENTIALS)
----------------------------
The environment uses the ESSENTIALS package for Stream Governance and Schema Registry. Stream Governance (ESSENTIALS) must be enabled for the environment in Confluent Cloud (Stream Governance → Enable in the console) so that the Schema Registry cluster exists. Terraform does not create the Schema Registry cluster; it only references the existing cluster via a data source and configures role bindings and outputs (e.g. schema_registry_url).

Schema Registry via NGINX (port 8443)
--------------------------------------
All Schema Registry traffic is routed through the NGINX proxy. NGINX listens on 8443 (HTTPS) and reverse-proxies to Confluent Schema Registry. The TLS certificate for 8443 is Terraform-generated (self-signed) so certs are handled automatically on tear-down/rebuild. The producer trusts this endpoint by setting **SCHEMA_REGISTRY_CA_CERT** to the path of the exported cert PEM; the Schema Registry client uses `ssl.ca.location` (no disabling of verification). When **SCHEMA_REGISTRY_URL** uses port 8443, **SCHEMA_REGISTRY_CA_CERT** is required. Export the cert from the Kubernetes secret `nginx-sr-tls` (namespace `cjackson-nginx`); see README for the exact `kubectl` command. **Hostname verification:** The cert CN is `nginx-schema-registry`. If clients connect by LB IP, TLS hostname verification fails. For local development, add an `/etc/hosts` entry mapping the NGINX LB IP to `nginx-schema-registry` and use `https://nginx-schema-registry:8443` as **SCHEMA_REGISTRY_URL**.

Producer environment for Schema Registry over NGINX
---------------------------------------------------
Required when the producer uses Schema Registry via NGINX: **SCHEMA_REGISTRY_URL** (e.g. `https://nginx-schema-registry:8443`), **SCHEMA_REGISTRY_CA_CERT** (path to the exported NGINX cert PEM). Optional but recommended: use the same hostname in `/etc/hosts` so the URL host matches the cert CN. See README and docs/env-variables.md.

Connectivity validation
-----------------------
Use these commands to verify NGINX reachability before running the full producer. **Kafka path (port 8082):** `nc -vz <host> 8082` and `openssl s_client -connect <host>:8082 -servername <host>`. **Schema Registry path (port 8443):** Export the NGINX cert, then `curl --cacert <path-to-cert.pem> -v https://nginx-schema-registry:8443/`. If the hostname does not match the cert CN, use the `/etc/hosts` workaround above.


Terraform
==========
All Terraform resources and data should be prefixed with "cjackson-".
Terraform code should output all relevant url endpoints links such as load balancer links if available, kafka cluster, nginx urls, schema registry urls, etc. 
All API Keys and secrets when generated should be output to GitHub Secrets and access by the Proucer and other components using GitHub Secrets, which can be visible by GitHub Admins with proper access.

Version control (tfplan ignored, commit / push / PR)
---------------------------------------------------
Terraform plan output files (e.g. `tfplan`, `terraform/tfplan`) must be listed in `.gitignore` and must not be committed; they can contain sensitive data and are environment-specific. The repo `.gitignore` should include `tfplan`, `*.tfplan`, and `terraform/tfplan`. If a plan file was previously committed, run `git rm --cached terraform/tfplan` (or the path used) to stop tracking it without deleting the file locally. The README or repo docs should describe the standard workflow for contributing: stage changes (`git add -A`, which respects `.gitignore`), commit, push the branch to origin, then open a PR (e.g. `gh pr create --base main --head <branch>` or the GitHub compare URL). This keeps tfplan out of history and gives a consistent commit/push/PR process.

Azure resource tagging
----------------------
Every Azure resource created by Terraform must carry default tags. Use the Azure provider's default_tags block so that all resources automatically receive:
- environment — Deployment environment (e.g. dev, staging, prod). May be set once and stored in a GitHub Environment variable (e.g. ENVIRONMENT).
- owner_email — Email of the owner (e.g. your_email@example.com). Set once and store in a GitHub Environment variable (e.g. OWNER_EMAIL) so CI and Terraform can use it without prompting; for local runs, pass via TF_VAR_owner_email.


GitHub
=======
GitHub repo is cursor-nginx-proxy
Use common GitHub patterns such as GitHub Secrets for API Keys and Secrets, and passwords.

Secrets (GitHub Secrets)
------------------------
Store the following in GitHub Secrets (repo or environment) so Terraform and CI can run without prompting:
- CONFLUENT_CLOUD_API_KEY — Confluent Cloud API key used by the Terraform Confluent provider to manage environments, clusters, Schema Registry, topics, and API keys.
- CONFLUENT_CLOUD_API_SECRET — Confluent Cloud API secret for the above.
Add Azure credentials (e.g. AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET) if CI runs Terraform plan/apply.

Environment variables (GitHub Environment)
-------------------------------------------
Create a GitHub Environment (e.g. "terraform") and set Environment variables (not secrets) so all Azure resources get the correct tags:
- OWNER_EMAIL — Owner email for the owner_email tag. Set this once; Terraform and CI use it for every Azure resource.
- ENVIRONMENT (optional) — Environment name for the environment tag (e.g. dev, prod). Defaults to dev if unset.

Documentation and diagrams
---------------------------
The repo should maintain a README.md file with deployment documentation, how to run the producer, and general documentation on the repo.
We should also maintain and update a Mermaid architecture diagram viewable in raw Mermaid format but also imported and converted to an Excalidraw drawing and visible in the README.md on GitHub.
Put this very spec plan into GitHub as well.
The README should show examples of terraform commands needed to deploy this workload as well as update the workload.
The README should document the required GitHub setup: Confluent and Azure secrets, and the GitHub Environment with OWNER_EMAIL (and optionally ENVIRONMENT) for Azure tags.
The README should document the self-signed certificate workflow for Schema Registry via NGINX: exporting the cert from the nginx-sr-tls secret, optional /etc/hosts mapping for hostname match (cert CN is nginx-schema-registry), and setting SCHEMA_REGISTRY_URL and SCHEMA_REGISTRY_CA_CERT. It should include a network connectivity test runbook: Kafka path (NGINX port 8082) with nc and openssl s_client; Schema Registry path (NGINX port 8443) with curl --cacert; and a note on the expected hostname mismatch when using the LB IP and how /etc/hosts resolves it. The README should also document version-control practice: Terraform plan files (tfplan) are ignored and must not be committed; and the standard workflow for commit, push, and opening a PR (see Version control above).
The README should also show confluent CLI commands to monitor the workload to test, view, and query the environment.
The README should also include example commands of how to monitor or query the NGINX proxy state and data flow.
The README should also include example commands to query the state of the Kubernetes environment.


