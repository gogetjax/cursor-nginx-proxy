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

# Read cluster with environment so provider sends environment ID (fixes "Environment ID not specified")
data "confluent_kafka_cluster" "cjackson_cluster" {
  id = confluent_kafka_cluster.cjackson_cluster.id
  environment {
    id = confluent_environment.cjackson_env.id
  }
}

# Schema Registry (look up existing cluster in environment; ESSENTIALS/Stream Governance)
data "confluent_schema_registry_cluster" "cjackson_sr" {
  environment {
    id = confluent_environment.cjackson_env.id
  }
}
