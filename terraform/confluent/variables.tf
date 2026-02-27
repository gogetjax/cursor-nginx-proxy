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

# Cloud API key used to create Kafka ACLs (Basic cluster); same as Confluent provider credentials
variable "cloud_api_key" {
  description = "Confluent Cloud API key for creating ACLs (e.g. CONFLUENT_CLOUD_API_KEY)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloud_api_secret" {
  description = "Confluent Cloud API secret for creating ACLs (e.g. CONFLUENT_CLOUD_API_SECRET)"
  type        = string
  sensitive   = true
  default     = ""
}
