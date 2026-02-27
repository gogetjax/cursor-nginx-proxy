# cjackson-: Kafka topics (cjackson- prefix); created after ACLs so SA has CREATE/DESCRIBE

resource "confluent_kafka_topic" "cjackson_sample_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }

  topic_name    = "${var.resource_prefix}sample-topic"
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.cjackson_kafka_api_key.id
    secret = confluent_api_key.cjackson_kafka_api_key.secret
  }

  partitions_count = 3

  depends_on = [
    confluent_kafka_acl.cjackson_sa_topic_create,
    confluent_kafka_acl.cjackson_sa_topic_describe
  ]
}
