# cjackson-: Root wiring for cursor-nginx-proxy

# Confluent provider: use variables or env CONFLUENT_CLOUD_API_KEY, CONFLUENT_CLOUD_API_SECRET
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key != "" ? var.confluent_cloud_api_key : null
  cloud_api_secret = var.confluent_cloud_api_secret != "" ? var.confluent_cloud_api_secret : null
}

# Confluent Cloud: Environment, Kafka cluster, Schema Registry, SA, API key, topic
module "confluent" {
  source = "./confluent"

  resource_prefix         = var.resource_prefix
  cloud                   = "AZURE"
  region                  = var.confluent_region
  admin_kafka_api_key     = var.admin_kafka_api_key
  admin_kafka_api_secret  = var.admin_kafka_api_secret
}

# Producer VNet (separate; Producer connects to NGINX over public internet)
module "producer" {
  source = "./producer"

  resource_prefix = var.resource_prefix
  location        = var.azure_location
  environment     = var.environment
  owner_email     = var.owner_email
}

# NGINX VNet and AKS (Kubernetes provider uses this AKS; see providers.tf)
module "nginx" {
  source = "./nginx"

  resource_prefix    = var.resource_prefix
  location           = var.azure_location
  kubernetes_version = null
  node_count         = 1
  environment        = var.environment
  owner_email        = var.owner_email
}

locals {
  nginx_lb_host          = try(kubernetes_service.cjackson_nginx_lb.status[0].load_balancer[0].ingress[0].ip, kubernetes_service.cjackson_nginx_lb.status[0].load_balancer[0].ingress[0].hostname, "")
  nginx_bootstrap_servers = local.nginx_lb_host != "" ? "${local.nginx_lb_host}:8082" : ""
}

# GitHub Actions secrets (from Confluent and NGINX outputs); set github_token to enable
module "github" {
  count  = var.github_token != "" ? 1 : 0
  source = "./github"

  repository          = var.github_repo
  bootstrap_servers   = local.nginx_bootstrap_servers
  schema_registry_url = module.confluent.schema_registry_url
  kafka_api_key       = module.confluent.kafka_api_key_id
  kafka_api_secret    = module.confluent.kafka_api_key_secret
  topic_name          = module.confluent.topic_name
}
