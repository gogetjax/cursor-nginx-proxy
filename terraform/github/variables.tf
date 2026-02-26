# cjackson-: GitHub module variables (secrets from root/caller)

variable "repository" {
  description = "GitHub repository name"
  type        = string
}

variable "bootstrap_servers" {
  description = "NGINX bootstrap URL (host:8082) for Producer"
  type        = string
  sensitive   = true
  default     = ""
}

variable "schema_registry_url" {
  description = "Confluent Schema Registry URL"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kafka_api_key" {
  description = "Kafka API key ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kafka_api_secret" {
  description = "Kafka API key secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "topic_name" {
  description = "Kafka topic name"
  type        = string
  default     = ""
}
