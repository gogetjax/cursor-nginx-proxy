# cjackson-: Service account with RBAC for Kafka cluster and Schema Registry (Standard cluster)

resource "confluent_service_account" "cjackson_sa" {
  display_name = "${var.resource_prefix}service-account"
  description  = "Service account for Kafka and Schema Registry access (DeveloperRead, DeveloperWrite)"
}

# Deployer SA: used by Terraform to create topics (Cloud Cluster Admin); no manual Admin Kafka key required
resource "confluent_service_account" "cjackson_deployer_sa" {
  display_name = "${var.resource_prefix}deployer-sa"
  description  = "Service account for Terraform topic creation (CloudClusterAdmin on Kafka cluster)"
}

resource "confluent_role_binding" "cjackson_deployer_kafka_admin" {
  principal   = "User:${confluent_service_account.cjackson_deployer_sa.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = "${data.confluent_kafka_cluster.cjackson_cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.cjackson_cluster.id}"
}

# Kafka cluster: DeveloperRead, DeveloperWrite (Standard supports resource roles)
resource "confluent_role_binding" "cjackson_kafka_cluster_developer" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_kafka_cluster.cjackson_cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.cjackson_cluster.id}"
}

resource "confluent_role_binding" "cjackson_kafka_cluster_developer_write" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_kafka_cluster.cjackson_cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.cjackson_cluster.id}"
}

# Schema Registry: DeveloperRead, DeveloperWrite (all subjects)
resource "confluent_role_binding" "cjackson_sr_developer" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.cjackson_sr.resource_name}/subject=*"
}

resource "confluent_role_binding" "cjackson_sr_developer_write" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.cjackson_sr.resource_name}/subject=*"
}
