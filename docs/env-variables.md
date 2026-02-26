# Environment Variable Practices

This document describes how environment variables are used for the Python Kafka Producer and related components. All sensitive values (API keys, secrets) must come from a secure store such as GitHub Secrets—never commit them to the repo.

## Producer

The Producer reads configuration from the environment (or a `.env` file that is **not** committed).

| Variable | Description | Source |
|----------|-------------|--------|
| `BOOTSTRAP_SERVERS` | Kafka bootstrap address. Use the **NGINX Load Balancer** host and port (e.g. `nginx-lb.example.eastus.cloudapp.azure.com:8082`). | Terraform output → GitHub Secret or `.env` |
| `SCHEMA_REGISTRY_URL` | Confluent Schema Registry base URL (HTTPS). | Terraform output → GitHub Secret or `.env` |
| `KAFKA_API_KEY` | Confluent Cloud Kafka API key (for SASL/PLAIN). | Terraform/Confluent → GitHub Secret |
| `KAFKA_API_SECRET` | Confluent Cloud Kafka API secret. | Terraform/Confluent → GitHub Secret |
| `TOPIC` | Target Kafka topic name (e.g. `cjackson-sample-topic`). | Terraform output → GitHub Secret or `.env` |
| `SSL_ENABLED` / TLS | TLS is always used when talking to the NGINX proxy and Confluent; the client is configured for TLS. | Optional override; default is TLS on. |

## Practices

- **No secrets in repo**: Do not put `.env` (with real secrets) under version control. Use `producer/.env.example` as a template only; add `producer/.env` to `.gitignore`.
- **GitHub Secrets**: In CI or when running from a machine with access to GitHub, populate the above from GitHub Actions secrets (or GitHub Environments). Admins with proper access can view/manage these.
- **TLS**: All connections (Producer → NGINX, NGINX → Confluent) use TLS over the public internet. The Producer connects to the NGINX proxy on port 8082 with TLS; the producer library uses the same credentials as for Confluent (API key/secret) for authentication after the TLS handshake.
- **Schema Registry**: Typically accessed over HTTPS using the same or a separate API key; the Confluent Kafka client can use Schema Registry for serialization. Ensure `SCHEMA_REGISTRY_URL` is set when using Avro/JSON Schema.

## Terraform / Azure default tags

Terraform applies default tags to all Azure resources. Set these so plan/apply and CI do not prompt:

| Variable / GitHub | Description |
|------------------|-------------|
| `TF_VAR_owner_email` / **OWNER_EMAIL** (Environment variable) | Owner email tag; set once in GitHub Environment (e.g. `terraform`) or export locally. |
| `TF_VAR_environment` / **ENVIRONMENT** (optional) | Environment name tag (e.g. `dev`, `prod`); defaults to `dev`. |

For Confluent, store **CONFLUENT_CLOUD_API_KEY** and **CONFLUENT_CLOUD_API_SECRET** in GitHub Secrets (repo or environment) so Terraform can manage Confluent resources in CI.

## Example (local development)

Copy the example file and fill with values from Terraform outputs or GitHub Secrets:

```bash
cp producer/.env.example producer/.env
# Edit producer/.env with real values (never commit this file)
```
