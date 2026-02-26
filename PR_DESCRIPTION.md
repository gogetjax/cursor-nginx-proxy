# Implement NGINX Kafka proxy (Terraform, Producer, docs, CI)

## Summary

End-to-end implementation per [spec_nginx_proxy.md](spec_nginx_proxy.md): Terraform provisions Confluent Cloud (Kafka + Schema Registry), two Azure VNets (Producer and NGINX), AKS with an NGINX stream proxy (port 8082, TLS passthrough to Confluent 9092), and optional GitHub Actions secrets. A Python Kafka producer sends sample data to a topic via the proxy using Schema Registry.

## What’s in this PR

### Terraform
- **Confluent** – Environment, Kafka cluster (Azure, basic), Schema Registry lookup (data source), service account with RBAC (DeveloperRead/DeveloperWrite), API key, topic (`cjackson-sample-topic`).
- **Producer VNet** – Dedicated VNet/subnet/NSG (Producer runs elsewhere; connects to NGINX over public internet).
- **NGINX VNet + AKS** – Second VNet, AKS cluster, Kubernetes Deployment/Service for NGINX (`nginx:latest`) with stream proxy config (listen 8082 → Confluent bootstrap 9092, SSL passthrough).
- **GitHub** – Optional module to sync Terraform outputs (bootstrap URL, Schema Registry URL, API key/secret, topic) into repo secrets; Confluent and GitHub providers use correct registry sources (`confluentinc/confluent`, `integrations/github`); Schema Registry uses a **data** source (no resource in provider).

### Producer
- Python app using `confluent-kafka` and Schema Registry (JSON Schema); reads `BOOTSTRAP_SERVERS`, `SCHEMA_REGISTRY_URL`, `KAFKA_API_KEY`, `KAFKA_API_SECRET`, `TOPIC` from env (or `.env` / GitHub Secrets). No secrets in code.

### Docs
- **README** – Architecture (Mermaid + Excalidraw), prerequisites, Terraform deploy/update, running the producer, Confluent CLI and NGINX/Kubernetes commands, optional CI.
- **docs/env-variables.md** – Env var usage and practices.
- **docs/architecture.mmd** & **docs/architecture.excalidraw** – Diagrams for README.

### CI
- **terraform-plan.yml** – `terraform plan` on PRs (uses Confluent, Azure, GitHub secrets as configured).
- **producer-smoke.yml** – Optional manual/scheduled run of the producer using GitHub Secrets.

## Fixes included
- **Provider sources** – Confluent and GitHub modules declare `confluentinc/confluent` and `integrations/github` in their `required_providers` so `terraform init`/`plan` resolve the correct providers.
- **Schema Registry** – Switched from `resource "confluent_schema_registry_cluster"` to `data "confluent_schema_registry_cluster"` (provider only supports the data source); all references updated to `data.confluent_schema_registry_cluster.cjackson_sr`.

## How to test
1. Set Confluent, Azure, and (optional) GitHub credentials (env or `tfvars`).
2. `cd terraform && terraform init && terraform plan`.
3. After apply, set Producer env from Terraform outputs (or GitHub Secrets) and run `python producer/producer.py`; consume from the topic via Confluent CLI or UI.

## Checklist
- [x] Terraform plan runs (provider resolution and Schema Registry data source).
- [x] All Confluent/Terraform resources use `cjackson-` prefix.
- [x] README documents deploy, producer run, monitoring, and optional CI.
- [x] No secrets committed; `.env` and sensitive outputs ignored/optional.
