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
