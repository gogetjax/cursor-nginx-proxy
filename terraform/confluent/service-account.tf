# cjackson-: Service account with RBAC for Schema Registry; Kafka access via API key only (Basic cluster)

resource "confluent_service_account" "cjackson_sa" {
  display_name = "${var.resource_prefix}service-account"
  description  = "Service account for Kafka and Schema Registry access (DeveloperRead, DeveloperWrite)"
}

# Basic Kafka clusters cannot use resource roles; Kafka access is via API key only. SR bindings below.

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
