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

# Deployer Admin (scoped directly to the cluster CRN; do not append /kafka=...)
resource "confluent_role_binding" "cjackson_deployer_kafka_admin" {
  principal   = "User:${confluent_service_account.cjackson_deployer_sa.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = data.confluent_kafka_cluster.cjackson_cluster.rbac_crn
}

# Developer Read (scoped to all topics in the specific Kafka cluster)
resource "confluent_role_binding" "cjackson_kafka_cluster_developer" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_kafka_cluster.cjackson_cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.cjackson_cluster.id}/topic=*"
}

# Developer Write (scoped to all topics in the specific Kafka cluster)
resource "confluent_role_binding" "cjackson_kafka_cluster_developer_write" {
  principal   = "User:${confluent_service_account.cjackson_sa.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_kafka_cluster.cjackson_cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.cjackson_cluster.id}/topic=*"
}

# Wait for RBAC to propagate before minting API keys and creating topics
resource "time_sleep" "wait_for_rbac" {
  create_duration = "60s"

  depends_on = [
    confluent_role_binding.cjackson_deployer_kafka_admin,
    confluent_role_binding.cjackson_kafka_cluster_developer,
    confluent_role_binding.cjackson_kafka_cluster_developer_write
  ]
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
