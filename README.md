# cursor-nginx-proxy

End-to-end Terraform and Python for a **Python Kafka Producer** that sends sample data to a Confluent Cloud Kafka topic (with Schema Registry), via an **NGINX TCP proxy** (SSL passthrough) on Azure Kubernetes Service (AKS). All infrastructure is in Azure; Confluent Cloud runs in its own VNet.

**Full specification:** [spec_nginx_proxy.md](spec_nginx_proxy.md).

## Architecture

- **Producer VNet** (Azure) → TLS over public internet → **NGINX VNet** (AKS, NGINX listening on **8082**) → TLS passthrough over public internet → **Confluent Cloud** (Kafka **9092**, Schema Registry).
- All Confluent and Terraform resources use the prefix `cjackson-` (configurable).

**Mermaid (raw):** [docs/architecture.mmd](docs/architecture.mmd)

```mermaid
flowchart LR
  subgraph producer_vnet [Producer VNet]
    Producer[Python Producer]
  end
  subgraph nginx_vnet [NGINX Proxy VNet]
    AKS[AKS]
    NGINX[NGINX Pod :8082]
  end
  subgraph confluent [Confluent Cloud VNet]
    Kafka[Kafka :9092]
    SR[Schema Registry]
  end
  Producer -->|"TLS (public internet)"| NGINX
  NGINX -->|"TLS passthrough (public internet)"| Kafka
  Producer -.->|"REST / env"| SR
```

**Excalidraw:** [docs/architecture.excalidraw](docs/architecture.excalidraw) — open in [Excalidraw](https://excalidraw.com) to view or edit.

## Prerequisites

- **Terraform** (>= 1.0)
- **Azure CLI** (`az login`, subscription set)
- **kubectl** (for NGINX/Kubernetes)
- **Confluent CLI** (optional, for monitoring)
- **Python 3.9+** (for the Producer)

## Terraform deploy and update

Credentials can be provided via variables or environment variables.

1. **Confluent Cloud:** Create an API key in Confluent Cloud (Cloud API keys) and set:
   - `CONFLUENT_CLOUD_API_KEY` and `CONFLUENT_CLOUD_API_SECRET`, or  
   - Terraform variables `confluent_cloud_api_key` and `confluent_cloud_api_secret`.

2. **Azure:** Set subscription and tenant, e.g.:
   - `export ARM_SUBSCRIPTION_ID="..."` and `ARM_TENANT_ID="..."`, or  
   - Use `terraform.tfvars` (do not commit) or `-var` for `azure_subscription_id` and `azure_tenant_id`.

3. **GitHub (optional):** To push secrets to the repo, set `GITHUB_TOKEN` or variable `github_token`, and `github_owner` / `github_repo` (default `cursor-nginx-proxy`).

**Deploy:**

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**Update:** Run `terraform plan` and `terraform apply` again. Re-apply after the NGINX Load Balancer is ready so that `nginx_bootstrap_servers` and GitHub secrets (if used) get the correct LB address.

**Example variable overrides (do not commit secrets):**

```bash
terraform plan \
  -var="azure_subscription_id=..." \
  -var="azure_tenant_id=..." \
  -var="confluent_cloud_api_key=..." \
  -var="confluent_cloud_api_secret=..." \
  -var="github_owner=YOUR_ORG" \
  -var="github_token=..."
```

## Running the Producer

The Producer reads **BOOTSTRAP_SERVERS** (NGINX LB:8082), **SCHEMA_REGISTRY_URL**, **KAFKA_API_KEY**, **KAFKA_API_SECRET**, and **TOPIC** from the environment (or a local `.env` file). These can come from Terraform outputs or GitHub Secrets.

**From Terraform outputs (after apply):**

```bash
export BOOTSTRAP_SERVERS="$(terraform -chdir=terraform output -raw nginx_bootstrap_servers)"
export SCHEMA_REGISTRY_URL="$(terraform -chdir=terraform output -raw schema_registry_url)"
export KAFKA_API_KEY="$(terraform -chdir=terraform output -raw kafka_api_key_id)"
export KAFKA_API_SECRET="$(terraform -chdir=terraform output -raw kafka_api_key_secret)"
export TOPIC="$(terraform -chdir=terraform output -raw topic_name)"
cd producer && pip install -r requirements.txt && python producer.py
```

**Using a local `.env`:** Copy `producer/.env.example` to `producer/.env`, fill in values (from outputs or GitHub Secrets), then:

```bash
cd producer
pip install -r requirements.txt
python producer.py
```

**Required env vars:** `BOOTSTRAP_SERVERS`, `SCHEMA_REGISTRY_URL`, `KAFKA_API_KEY`, `KAFKA_API_SECRET`, `TOPIC`. See [docs/env-variables.md](docs/env-variables.md).

## GitHub Secrets (Producer and workflows)

When Terraform runs with a GitHub token, it creates or updates these **repository secrets** (visible to repo admins):

- **BOOTSTRAP_SERVERS** — NGINX LB host:8082  
- **SCHEMA_REGISTRY_URL** — Confluent Schema Registry URL  
- **KAFKA_API_KEY** — Kafka API key ID  
- **KAFKA_API_SECRET** — Kafka API secret  
- **TOPIC** — Kafka topic name  

Use these in GitHub Actions or locally (e.g. `${{ secrets.BOOTSTRAP_SERVERS }}` in workflows, or copy into `.env` for local runs).

## Confluent CLI – monitor and test

After logging in and selecting the correct environment/cluster:

```bash
# Login (browser or service account)
confluent login

# List environments and clusters
confluent environment list
confluent kafka cluster list

# List topics and consume (replace cluster-id and topic name from Terraform outputs)
confluent kafka topic list --cluster <cluster-id>
confluent kafka topic consume cjackson-sample-topic --cluster <cluster-id> --from-beginning

# Schema Registry (replace SR endpoint from Terraform output)
confluent schema-registry subject list --url <schema-registry-url>
confluent schema-registry subject describe <subject> --url <schema-registry-url>
```

Get cluster ID and Schema Registry URL from Terraform:

```bash
terraform -chdir=terraform output schema_registry_url
terraform -chdir=terraform output kafka_bootstrap_endpoint
```

## NGINX and Kubernetes

**Load Balancer and NGINX service:**

```bash
kubectl get svc -n cjackson-nginx
# Note the EXTERNAL-IP or hostname for the nginx-lb service (port 8082)
```

**NGINX pod logs:**

```bash
kubectl logs -n cjackson-nginx -l app=nginx -f
```

**Inspect NGINX config inside the pod:**

```bash
kubectl exec -n cjackson-nginx deploy/nginx -- cat /etc/nginx/nginx.conf
```

**Verify TCP flow:** The stream block listens on 8082 and forwards to Confluent bootstrap (e.g. `pkc-xxx:9092`) without decrypting TLS (SSL passthrough).

## Kubernetes state

```bash
kubectl get nodes
kubectl get pods -n cjackson-nginx
kubectl get svc -n cjackson-nginx
kubectl describe deployment nginx -n cjackson-nginx
```

Get kubeconfig for the AKS cluster (if not already set):

```bash
az aks get-credentials --resource-group <nginx-rg> --name <aks-name>
# Resource group and AKS name are in Terraform outputs or Azure portal
```

## Manual validation

1. Run `terraform apply` and wait for the NGINX Load Balancer to get an external IP/hostname.
2. Set Producer env vars (from Terraform outputs or GitHub Secrets).
3. Run the Producer: `python producer/producer.py`.
4. Consume messages with Confluent CLI or Confluent Cloud UI to confirm records arrive on the topic.

## Optional CI

- **.github/workflows/terraform-plan.yml** — Runs `terraform plan` on PRs (set `CONFLUENT_CLOUD_API_KEY`, `CONFLUENT_CLOUD_API_SECRET`, Azure and optional GitHub secrets in the repo).
- **.github/workflows/producer-smoke.yml** — Manual or scheduled run of the Producer using GitHub Secrets (`BOOTSTRAP_SERVERS`, `SCHEMA_REGISTRY_URL`, `KAFKA_API_KEY`, `KAFKA_API_SECRET`, `TOPIC`); use after Terraform apply has populated those secrets.

## Repository layout

- **terraform/** — Root and modules: Confluent, Producer VNet, NGINX VNet + AKS, Kubernetes (NGINX Pod/Service), GitHub secrets.
- **producer/** — Python Kafka producer (Schema Registry), `requirements.txt`, `.env.example`, `Dockerfile`.
- **docs/** — Architecture diagram (Mermaid + Excalidraw), [env-variables.md](docs/env-variables.md).
