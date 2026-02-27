# cjackson-: Confluent module input variables

variable "resource_prefix" {
  description = "Prefix for Confluent resource names (e.g. cjackson-)"
  type        = string
}

variable "cloud" {
  description = "Confluent Cloud provider (e.g. AZURE)"
  type        = string
  default     = "AZURE"
}

variable "region" {
  description = "Confluent Cloud region (e.g. useast2)"
  type        = string
}

variable "admin_kafka_api_key" {
  description = "Kafka API Key (Admin) used by Terraform to create topics"
  type        = string
  sensitive   = true
}

variable "admin_kafka_api_secret" {
  description = "Kafka API Secret (Admin) used by Terraform to create topics"
  type        = string
  sensitive   = true
}
