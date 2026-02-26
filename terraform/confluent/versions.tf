# Confluent module: require Confluent provider (not hashicorp namespace)
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
  }
}
