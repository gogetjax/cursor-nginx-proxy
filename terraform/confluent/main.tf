# cjackson-: Confluent Cloud Environment, Kafka cluster, and Schema Registry (ESSENTIALS)

resource "confluent_environment" "cjackson_env" {
  display_name = "${var.resource_prefix}environment"

  lifecycle {
    prevent_destroy = false
  }
}

# Kafka cluster on Confluent Cloud (Azure, ESSENTIALS)
resource "confluent_kafka_cluster" "cjackson_cluster" {
  display_name = "${var.resource_prefix}kafka-cluster"
  availability = "SINGLE_ZONE"
  cloud        = var.cloud
  region       = var.region

  basic {}

  environment {
    id = confluent_environment.cjackson_env.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Schema Registry (in same environment; ESSENTIALS includes Governance + Schema Registry)
resource "confluent_schema_registry_cluster" "cjackson_sr" {
  display_name = "${var.resource_prefix}schema-registry"

  package = "ESSENTIALS"

  environment {
    id = confluent_environment.cjackson_env.id
  }

  region {
    id = confluent_kafka_cluster.cjackson_cluster.region
  }

  lifecycle {
    prevent_destroy = false
  }
}
