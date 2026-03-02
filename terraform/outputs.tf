# cjackson-: Root outputs (URLs, endpoints; secrets pushed to GitHub)

output "nginx_loadbalancer_host" {
  description = "NGINX Load Balancer host (Producer bootstrap: this host + port 8082)"
  value       = local.nginx_lb_host != "" ? local.nginx_lb_host : "pending"
}

output "nginx_bootstrap_servers" {
  description = "Producer BOOTSTRAP_SERVERS value (NGINX LB:8082)"
  value       = local.nginx_bootstrap_servers != "" ? local.nginx_bootstrap_servers : "pending (re-apply after LB is ready)"
}

output "kafka_bootstrap_endpoint" {
  description = "Confluent Kafka bootstrap endpoint (direct; NGINX proxies to this)"
  value       = module.confluent.kafka_bootstrap_endpoint
}

output "schema_registry_url" {
  description = "Schema Registry URL via NGINX (HTTPS, port 8443); use for Producer and CI. Pending until LB is ready."
  value       = local.schema_registry_url_via_nginx != "" ? local.schema_registry_url_via_nginx : "pending (re-apply after LB is ready)"
}

output "topic_name" {
  description = "Kafka topic name (cjackson- prefix)"
  value       = module.confluent.topic_name
}

output "kafka_api_key_id" {
  description = "Kafka API key ID (sensitive; also in GitHub Secrets)"
  value       = module.confluent.kafka_api_key_id
  sensitive   = true
}

output "kafka_api_key_secret" {
  description = "Kafka API key secret (sensitive; also in GitHub Secrets)"
  value       = module.confluent.kafka_api_key_secret
  sensitive   = true
}

output "schema_registry_api_key_id" {
  description = "Schema Registry API key ID (for Producer SR client; use to avoid 401 when SR is via NGINX)"
  value       = module.confluent.schema_registry_api_key_id
  sensitive   = true
}

output "schema_registry_api_key_secret" {
  description = "Schema Registry API key secret (for Producer SR client)"
  value       = module.confluent.schema_registry_api_key_secret
  sensitive   = true
}
