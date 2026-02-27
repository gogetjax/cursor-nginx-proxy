# cjackson-: Kafka topics (cjackson- prefix); created with Admin key; apps use Developer key from outputs

resource "confluent_kafka_topic" "cjackson_sample_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }

  topic_name    = "${var.resource_prefix}sample-topic"
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = var.admin_kafka_api_key
    secret = var.admin_kafka_api_secret
  }

  partitions_count = 3
}
