# cjackson-: Service account with RBAC for Kafka cluster and Schema Registry

resource "confluent_service_account" "cjackson_sa" {
  display_name = "${var.resource_prefix}service-account"
  description  = "Service account for Kafka and Schema Registry access (DeveloperRead, DeveloperWrite)"
}

# Kafka Cluster role binding: DeveloperRead, DeveloperWrite for the cluster
resource "confluent_role_binding" "cjackson_kafka_cluster_developer" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperRead"
  crn_pattern = confluent_kafka_cluster.cjackson_cluster.rbac_crn
}

resource "confluent_role_binding" "cjackson_kafka_cluster_developer_write" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = confluent_kafka_cluster.cjackson_cluster.rbac_crn
}

# Schema Registry: DeveloperRead, DeveloperWrite (all subjects)
resource "confluent_role_binding" "cjackson_sr_developer" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_schema_registry_cluster.cjackson_sr.resource_name}/subject=*"
}

resource "confluent_role_binding" "cjackson_sr_developer_write" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_schema_registry_cluster.cjackson_sr.resource_name}/subject=*"
}
