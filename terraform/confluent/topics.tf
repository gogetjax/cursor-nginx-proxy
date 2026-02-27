# cjackson-: Kafka topics (cjackson- prefix); created with deployer API key; apps use Developer key from outputs

resource "confluent_kafka_topic" "cjackson_sample_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }

  topic_name    = "${var.resource_prefix}sample-topic"
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.cjackson_deployer_kafka_key.id
    secret = confluent_api_key.cjackson_deployer_kafka_key.secret
  }

  partitions_count = 3

  depends_on = [confluent_api_key.cjackson_deployer_kafka_key]
}
