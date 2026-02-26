# cjackson-: Confluent module outputs (bootstrap, Schema Registry, topic; API key/secret sensitive)

output "kafka_bootstrap_endpoint" {
  description = "Kafka bootstrap endpoint (e.g. SASL_SSL://pkc-xxx:9092); use host:port for NGINX proxy_pass"
  value       = confluent_kafka_cluster.cjackson_cluster.bootstrap_endpoint
}

output "kafka_bootstrap_host" {
  description = "Kafka bootstrap host for NGINX proxy_pass (strip SASL_SSL:// and use host:9092)"
  value       = replace(replace(confluent_kafka_cluster.cjackson_cluster.bootstrap_endpoint, "SASL_SSL://", ""), "SASL_PLAINTEXT://", "")
}

output "schema_registry_url" {
  description = "Schema Registry REST URL (HTTPS)"
  value       = confluent_schema_registry_cluster.cjackson_sr.rest_endpoint
}

output "topic_name" {
  description = "Sample Kafka topic name (cjackson- prefix)"
  value       = confluent_kafka_topic.cjackson_sample_topic.topic_name
}

output "kafka_api_key_id" {
  description = "Kafka API key ID (for Producer)"
  value       = confluent_api_key.cjackson_kafka_api_key.id
  sensitive   = true
}

output "kafka_api_key_secret" {
  description = "Kafka API key secret (for Producer)"
  value       = confluent_api_key.cjackson_kafka_api_key.secret
  sensitive   = true
}
