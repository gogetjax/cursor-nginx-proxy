# cjackson-: Root input variables for cursor-nginx-proxy

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_location" {
  description = "Azure region (e.g. East US)"
  type        = string
  default     = "eastus"
}

variable "resource_prefix" {
  description = "Prefix for Terraform and Confluent resource names (e.g. cjackson-)"
  type        = string
  default     = "cjackson-"
}

# Confluent Cloud (set via env CONFLUENT_CLOUD_API_KEY, CONFLUENT_CLOUD_API_SECRET or pass here)
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API key for Terraform provider"
  type        = string
  sensitive   = true
  default     = ""
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API secret for Terraform provider"
  type        = string
  sensitive   = true
  default     = ""
}

# GitHub (token for managing repo and secrets)
variable "github_token" {
  description = "GitHub personal access token (or GITHUB_TOKEN) for provider and secrets"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_owner" {
  description = "GitHub owner (org or user) for the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "cursor-nginx-proxy"
}

variable "confluent_region" {
  description = "Confluent Cloud region (e.g. eastus2 for Azure)"
  type        = string
  default     = "eastus2"
}
