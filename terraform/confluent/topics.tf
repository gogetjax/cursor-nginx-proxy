# cjackson-: Kafka topics (cjackson- prefix); SA has DeveloperRead/DeveloperWrite via RBAC

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

  depends_on = [time_sleep.wait_for_rbac]
}
