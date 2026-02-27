# cjackson-: API keys for Kafka cluster and Schema Registry (Producer uses Kafka key + dedicated SR key)
# managed_resource uses data source so cluster is read with environment.

resource "confluent_api_key" "cjackson_kafka_api_key" {
  display_name = "${var.resource_prefix}kafka-api-key"
  description  = "Kafka API key for Producer (and Schema Registry when using same credentials)"

  owner {
    id          = confluent_service_account.cjackson_sa.id
    api_version = confluent_service_account.cjackson_sa.api_version
    kind        = confluent_service_account.cjackson_sa.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.cjackson_cluster.id
    api_version = data.confluent_kafka_cluster.cjackson_cluster.api_version
    kind        = data.confluent_kafka_cluster.cjackson_cluster.kind

    environment {
      id = confluent_environment.cjackson_env.id
    }
  }

  depends_on = [
    time_sleep.wait_for_rbac
  ]
}

# Schema Registry API key (dedicated; Kafka key cannot be used for Schema Registry REST API)
resource "confluent_api_key" "cjackson_sr_api_key" {
  display_name = "${var.resource_prefix}sr-api-key"
  description  = "Schema Registry API key for Producer"

  owner {
    id          = confluent_service_account.cjackson_sa.id
    api_version = confluent_service_account.cjackson_sa.api_version
    kind        = confluent_service_account.cjackson_sa.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.cjackson_sr.id
    api_version = data.confluent_schema_registry_cluster.cjackson_sr.api_version
    kind        = data.confluent_schema_registry_cluster.cjackson_sr.kind
    environment {
      id = confluent_environment.cjackson_env.id
    }
  }

  depends_on = [
    time_sleep.wait_for_rbac
  ]
}

# Deployer Kafka API key: used only by Terraform to create topics (no manual Admin key required)
resource "confluent_api_key" "cjackson_deployer_kafka_key" {
  display_name = "${var.resource_prefix}deployer-kafka-key"
  description  = "Kafka API key for Terraform topic creation (deployer SA has CloudClusterAdmin)"

  owner {
    id          = confluent_service_account.cjackson_deployer_sa.id
    api_version = confluent_service_account.cjackson_deployer_sa.api_version
    kind        = confluent_service_account.cjackson_deployer_sa.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.cjackson_cluster.id
    api_version = data.confluent_kafka_cluster.cjackson_cluster.api_version
    kind        = data.confluent_kafka_cluster.cjackson_cluster.kind

    environment {
      id = confluent_environment.cjackson_env.id
    }
  }

  depends_on = [
    time_sleep.wait_for_rbac
  ]
}
