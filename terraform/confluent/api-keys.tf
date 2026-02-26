# cjackson-: API keys for Kafka cluster (used by Producer; same SA can access Schema Registry)

resource "confluent_api_key" "cjackson_kafka_api_key" {
  display_name = "${var.resource_prefix}kafka-api-key"
  description  = "Kafka API key for Producer (and Schema Registry when using same credentials)"

  owner {
    id          = confluent_service_account.cjackson_sa.id
    api_version = confluent_service_account.cjackson_sa.api_version
    kind        = confluent_service_account.cjackson_sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cjackson_cluster.id
    api_version = confluent_kafka_cluster.cjackson_cluster.api_version
    kind        = confluent_kafka_cluster.cjackson_cluster.kind
  }

  environment {
    id = confluent_environment.cjackson_env.id
  }
}
