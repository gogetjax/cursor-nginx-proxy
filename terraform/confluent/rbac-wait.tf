# cjackson-: Wait for Confluent RBAC to propagate before creating topic (avoids 403 on first apply)

resource "time_sleep" "wait_for_rbac" {
  depends_on = [
    confluent_role_binding.cjackson_kafka_cluster_developer,
    confluent_role_binding.cjackson_kafka_cluster_developer_write
  ]
  create_duration = "30s"
}
