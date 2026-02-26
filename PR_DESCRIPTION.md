# Implement NGINX Kafka proxy (Terraform, Producer, docs, CI)

## Summary

Implements the full stack from [spec_nginx_proxy.md](spec_nginx_proxy.md):

- **Terraform:** Confluent Cloud (Environment, Kafka cluster, Schema Registry, service account, API key, topic), Producer VNet, NGINX VNet + AKS, Kubernetes NGINX stream proxy (listen 8082, TLS passthrough to Confluent 9092), optional GitHub Actions secrets.
- **Producer:** Python Kafka producer using Schema Registry; config via env (or GitHub Secrets).
- **Docs:** README (deploy, run producer, Confluent CLI, NGINX/K8s commands), architecture (Mermaid + Excalidraw), env-variables.md.
- **CI:** Optional `terraform-plan` and `producer-smoke` workflows.

## Branch

`feature/nginx-kafka-proxy-implementation`

## How to open this PR

From your machine (with GitHub access):

```bash
cd /home/cjackson/code/cursor-nginx-proxy
git push -u origin feature/nginx-kafka-proxy-implementation
```

Then either:

- **GitHub CLI:** `gh pr create --base main --head feature/nginx-kafka-proxy-implementation --title "Implement NGINX Kafka proxy" --body-file PR_DESCRIPTION.md`
- **GitHub UI:** Go to https://github.com/gogetjax/cursor-nginx-proxy/compare/main...feature/nginx-kafka-proxy-implementation and click “Create pull request”. Paste the contents of this file as the PR description.
