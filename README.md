# cursor-nginx-proxy

End-to-end Terraform and Python for a **Python Kafka Producer** that sends sample data to a Confluent Cloud Kafka topic (with Schema Registry), via an **NGINX TCP proxy** (SSL passthrough) on Azure Kubernetes Service (AKS). All infrastructure is in Azure; Confluent Cloud runs in its own VNet. Every Azure resource is tagged with **environment** and **owner_email** (see [Required: GitHub setup](#required-github-setup-for-ci-and-tagging) and [spec](spec_nginx_proxy.md)).

**Full specification:** [spec_nginx_proxy.md](spec_nginx_proxy.md).

## Architecture

- **Producer VNet** (Azure) → TLS over public internet → **NGINX VNet** (AKS, NGINX on **8082** for Kafka, **8443** for Schema Registry) → Confluent Cloud (Kafka **9092**, Schema Registry). Both Kafka and Schema Registry traffic go through NGINX.
- All Confluent and Terraform resources use the prefix `cjackson-` (configurable).

**Mermaid (raw):** [docs/architecture.mmd](docs/architecture.mmd)

```mermaid
flowchart LR
  subgraph producer_vnet [Producer VNet]
    Producer[Python Producer]
  end
  subgraph nginx_vnet [NGINX Proxy VNet]
    AKS[AKS]
    NGINX[NGINX Pod :8082 / :8443]
  end
  subgraph confluent [Confluent Cloud VNet]
    Kafka[Kafka :9092]
    SR[Schema Registry]
  end
  Producer -->|"TLS (public internet)"| NGINX
  NGINX -->|"TLS passthrough (public internet)"| Kafka
  Producer -->|"HTTPS :8443"| NGINX
  NGINX -->|"HTTPS reverse proxy"| SR
```

**Excalidraw:** [docs/architecture.excalidraw](docs/architecture.excalidraw) — open in [Excalidraw](https://excalidraw.com) to view or edit.

## Prerequisites

- **Terraform** (>= 1.0)
- **Azure CLI** (`az login`, subscription set)
- **kubectl** (for NGINX/Kubernetes)
- **Confluent CLI** (optional, for monitoring)
- **Python 3.9+** (for the Producer)

## Required: GitHub setup (for CI and tagging)

All Azure resources are tagged with `environment` and `owner_email`. Configure GitHub once so Terraform and CI use them.

### 1. GitHub Secrets (required for Terraform plan/apply in CI)

Store the **Confluent Cloud** API key and secret so Terraform can manage Confluent resources:

- **CONFLUENT_CLOUD_API_KEY** — Confluent Cloud API key (Cloud API keys in Confluent Cloud console).
- **CONFLUENT_CLOUD_API_SECRET** — Confluent Cloud API secret.

Also add Azure credentials if CI runs Terraform plan/apply:

- **AZURE_SUBSCRIPTION_ID**, **AZURE_TENANT_ID**, **AZURE_CLIENT_ID**, **AZURE_CLIENT_SECRET** (or equivalent).

Repo path: **Settings → Secrets and variables → Actions** (or **Environments → [environment] → Secrets**).

### 2. GitHub Environment and `owner_email` (required for Azure tags)

Create a GitHub **Environment** (e.g. `terraform`) and set **Environment variables** (not secrets) so every Azure resource gets the correct tags:

- **OWNER_EMAIL** — Your email (e.g. `your_email@example.com`). Used as the `owner_email` tag on all Azure resources. Set this once; CI and Terraform will use it.
- **ENVIRONMENT** (optional) — Name for the deployment (e.g. `dev`, `staging`, `prod`). Defaults to `dev` if unset.

Repo path: **Settings → Environments → Add environment** (e.g. `terraform`) → **Environment variables** → add `OWNER_EMAIL` and optionally `ENVIRONMENT`.

For local runs, set `TF_VAR_owner_email` and optionally `TF_VAR_environment` (e.g. `export TF_VAR_owner_email=your_email@example.com`).

## Terraform deploy and update

Credentials can be provided via variables or environment variables.

1. **Confluent Cloud:** Use GitHub Secrets **CONFLUENT_CLOUD_API_KEY** and **CONFLUENT_CLOUD_API_SECRET** in CI, or locally set the same env vars or Terraform variables `confluent_cloud_api_key` and `confluent_cloud_api_secret`. Topic creation is fully automated (see [Topic creation (fully automated)](#topic-creation-fully-automated)).

2. **Azure:** Set subscription and tenant, e.g.:
   - `export ARM_SUBSCRIPTION_ID="..."` and `ARM_TENANT_ID="..."`, or  
   - Use `terraform.tfvars` (do not commit) or `-var` for `azure_subscription_id` and `azure_tenant_id`.

3. **Tags (required):** Set `owner_email` (and optionally `environment`):
   - From GitHub: use Environment `terraform` with variable **OWNER_EMAIL** (and **ENVIRONMENT**).
   - Locally: `export TF_VAR_owner_email=your_email@example.com` and optionally `TF_VAR_environment=dev`.

4. **GitHub (optional):** To push secrets to the repo, set `GITHUB_TOKEN` or variable `github_token`, and `github_owner` / `github_repo` (default `cursor-nginx-proxy`).

### Confluent Cloud – Stream Governance (Schema Registry)

Schema Registry uses the **ESSENTIALS** package for Stream Governance. The Confluent Terraform provider does not create the Schema Registry cluster; it only looks up an existing one. Before running `terraform apply`, enable Stream Governance for your Confluent Cloud environment:

1. In Confluent Cloud, open the environment (e.g. `cjackson-environment` after the first apply that creates it, or create the environment and enable governance before a full apply).
2. **Enable Stream Governance** with the **ESSENTIALS** package (Stream Governance → Enable, or Set up Schema Registry). One Schema Registry cluster per environment will be created.
3. Re-run `terraform apply` so the Terraform data source can find the Schema Registry cluster and populate outputs (e.g. `schema_registry_url`) and role bindings.

The Kafka cluster is Standard tier; Kafka access uses RBAC (DeveloperRead, DeveloperWrite) on the cluster. Schema Registry uses the same service account with RBAC on the Schema Registry cluster.

### Schema Registry via NGINX (port 8443)

Schema Registry traffic is routed through the NGINX proxy so that both Kafka and Schema Registry go through NGINX. NGINX listens on **8443** (HTTPS) and reverse-proxies to Confluent Schema Registry. The TLS certificate for port 8443 is **Terraform-generated** (self-signed) so every tear-down/rebuild handles certs automatically. The Producer uses **SCHEMA_REGISTRY_CA_CERT** (path to the NGINX cert PEM) so the Schema Registry client trusts the endpoint via `ssl.ca.location`. When `SCHEMA_REGISTRY_URL` uses port 8443, `SCHEMA_REGISTRY_CA_CERT` is required. Use the `schema_registry_url` Terraform output (e.g. `https://<nginx-lb>:8443`) and export the cert from the `nginx-sr-tls` Kubernetes secret for local runs; see [Self-signed cert and hostname](#self-signed-cert-and-hostname) and [Network connectivity tests](#network-connectivity-tests).

### Topic creation (fully automated)

Terraform creates a **deployer** service account with **CloudClusterAdmin** on the Kafka cluster and a Kafka API key for that SA. The topic is created using this deployer key, so **no manual Admin Kafka API key** is required. The only Confluent credential you must provide is the **Cloud API key** (CONFLUENT_CLOUD_API_KEY / CONFLUENT_CLOUD_API_SECRET) for the Terraform provider; it must have permissions to create service accounts and role bindings (org or environment admin). The **Developer** key (used by the Producer and GitHub Secrets) is still created by Terraform for application use.

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
  -var="owner_email=your_email@example.com" \
  -var="environment=dev" \
  -var="confluent_cloud_api_key=..." \
  -var="confluent_cloud_api_secret=..." \
  -var="github_owner=YOUR_ORG" \
  -var="github_token=..."
```

## Running the Producer

The Producer reads **BOOTSTRAP_SERVERS** (NGINX LB:8082), **SCHEMA_REGISTRY_URL**, **KAFKA_API_KEY**, **KAFKA_API_SECRET**, **TOPIC**, and (when using Schema Registry via NGINX on port 8443) **SCHEMA_REGISTRY_CA_CERT** from the environment or a local `.env` file. For Schema Registry via NGINX, use the **dedicated Schema Registry API key** (not the Kafka key) to avoid 401 Unauthorized; set **SCHEMA_REGISTRY_API_KEY** and **SCHEMA_REGISTRY_API_SECRET** from Terraform outputs below.

**From Terraform outputs (after apply):**

```bash
export BOOTSTRAP_SERVERS="$(terraform -chdir=terraform output -raw nginx_bootstrap_servers)"
export SCHEMA_REGISTRY_URL="$(terraform -chdir=terraform output -raw schema_registry_url)"
export KAFKA_API_KEY="$(terraform -chdir=terraform output -raw kafka_api_key_id)"
export KAFKA_API_SECRET="$(terraform -chdir=terraform output -raw kafka_api_key_secret)"
export TOPIC="$(terraform -chdir=terraform output -raw topic_name)"
# Required when SCHEMA_REGISTRY_URL uses NGINX :8443 (see Self-signed cert below)
export SCHEMA_REGISTRY_CA_CERT="$HOME/nginx-sr-cert.pem"
# Dedicated Schema Registry API key (avoids 401 when SR is via NGINX)
export SCHEMA_REGISTRY_API_KEY="$(terraform -chdir=terraform output -raw schema_registry_api_key_id)"
export SCHEMA_REGISTRY_API_SECRET="$(terraform -chdir=terraform output -raw schema_registry_api_key_secret)"
cd producer && pip install -r requirements.txt && python producer.py
```

**Using a local `.env`:** Copy `producer/.env.example` to `producer/.env`, fill in values (including `SCHEMA_REGISTRY_CA_CERT` and `SCHEMA_REGISTRY_API_KEY` / `SCHEMA_REGISTRY_API_SECRET` when using NGINX for Schema Registry), then run the producer from the `producer/` directory.

**Required env vars:** `BOOTSTRAP_SERVERS`, `SCHEMA_REGISTRY_URL`, `KAFKA_API_KEY`, `KAFKA_API_SECRET`, `TOPIC`. When `SCHEMA_REGISTRY_URL` points to NGINX (port 8443), also set `SCHEMA_REGISTRY_CA_CERT` and the dedicated **SCHEMA_REGISTRY_API_KEY** / **SCHEMA_REGISTRY_API_SECRET** (from Terraform outputs) so SR returns 200 instead of 401. See [docs/env-variables.md](docs/env-variables.md).

### Self-signed cert and hostname

When Schema Registry is reached via NGINX (`https://<host>:8443`), the server uses a Terraform-generated self-signed cert. The producer needs the CA cert and a hostname that matches the cert (CN is `nginx-schema-registry`).

1. **Export the cert** from the AKS secret (run after `kubectl` is configured for your cluster):

   ```bash
   kubectl get secret nginx-sr-tls -n cjackson-nginx -o jsonpath='{.data.cert\.pem}' | base64 -d > ~/nginx-sr-cert.pem
   ```

2. **Match hostname to cert:** If you connect by IP, TLS hostname verification will fail (cert subject is `nginx-schema-registry`). Add a hosts entry so the same hostname is used in the URL:

   ```bash
   echo "<EXTERNAL-IP> nginx-schema-registry" | sudo tee -a /etc/hosts
   ```

   Then set `SCHEMA_REGISTRY_URL="https://nginx-schema-registry:8443"` (and ensure `BOOTSTRAP_SERVERS` still uses the IP or the same hostname if desired).

3. Set **SCHEMA_REGISTRY_CA_CERT** to the path of the exported PEM (e.g. `$HOME/nginx-sr-cert.pem`).

### Network connectivity tests

Use these to verify NGINX reachability without running the full producer.

**Kafka path (NGINX port 8082):**

```bash
# Replace <host> with NGINX LB EXTERNAL-IP or hostname
nc -vz <host> 8082
openssl s_client -connect <host>:8082 -servername <host>
```

**Schema Registry path (NGINX port 8443):**  
Without the CA cert, `curl` will report a hostname mismatch (cert CN is `nginx-schema-registry`). Use the exported cert and a hostname that matches the cert (e.g. `nginx-schema-registry` in `/etc/hosts`):

```bash
curl --cacert ~/nginx-sr-cert.pem -v https://nginx-schema-registry:8443/
```

If you use the LB IP in the URL, you will see: `certificate subject name 'nginx-schema-registry' does not match target host name '<ip>'`. Fix by using the hostname in the URL and the `/etc/hosts` entry above.

### Kafka TLS through NGINX (port 8082)

Kafka uses TLS passthrough: the broker cert is Confluent's, not NGINX's. If you see **broker certificate could not be verified** or **certificate verify failed** when connecting to `BOOTSTRAP_SERVERS` (e.g. an IP like `4.x.x.x:8082`):

1. **CA trust:** Set **KAFKA_SSL_CA_LOCATION** to your OS CA bundle so the producer can verify Confluent's cert (e.g. `/etc/ssl/certs/ca-certificates.crt` on Ubuntu/WSL).
2. **Hostname mismatch:** When using an IP for bootstrap through the proxy, the cert's hostname won't match. Set **KAFKA_SSL_VERIFY_HOSTNAME=false** to disable only hostname verification (CA verification stays on). This sets `ssl.endpoint.identification.algorithm` to `"none"` (librdkafka does not accept an empty value). See [docs/env-variables.md](docs/env-variables.md).

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

## Troubleshooting

- **Azure: "The refresh token has expired or is invalid"** — The Azure CLI token can expire due to sign-in frequency or conditional access. Re-authenticate:
  ```bash
  az logout
  az login --tenant "<your-tenant-id>" --scope "https://graph.microsoft.com/.default"
  ```
  Use the tenant ID that matches your Azure login (e.g. from the error message). Then run `terraform plan` again.

## Optional CI

- **.github/workflows/terraform-plan.yml** — Runs `terraform plan` on PRs. Requires: GitHub Secrets **CONFLUENT_CLOUD_API_KEY**, **CONFLUENT_CLOUD_API_SECRET**, and Azure credentials; a GitHub Environment named **terraform** with Environment variable **OWNER_EMAIL** (and optionally **ENVIRONMENT**) for Azure default tags.
- **.github/workflows/producer-smoke.yml** — Manual or scheduled run of the Producer using GitHub Secrets (`BOOTSTRAP_SERVERS`, `SCHEMA_REGISTRY_URL`, `KAFKA_API_KEY`, `KAFKA_API_SECRET`, `TOPIC`); use after Terraform apply has populated those secrets.

## Repository layout

- **terraform/** — Root and modules: Confluent, Producer VNet, NGINX VNet + AKS, Kubernetes (NGINX Pod/Service), GitHub secrets. Azure provider uses default_tags (`environment`, `owner_email`) on all resources.
- **producer/** — Python Kafka producer (Schema Registry), `requirements.txt`, `.env.example`, `Dockerfile`.
- **docs/** — Architecture diagram (Mermaid + Excalidraw), [env-variables.md](docs/env-variables.md).

See [spec_nginx_proxy.md](spec_nginx_proxy.md) for Azure tagging, GitHub Secrets (Confluent API key/secret), and GitHub Environment (OWNER_EMAIL, ENVIRONMENT).
