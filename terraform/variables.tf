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

# Default tags applied to all Azure resources (set owner_email via TF_VAR_owner_email or GitHub Environment OWNER_EMAIL)
variable "owner_email" {
  description = "Owner email for Azure resource tags (set in GitHub Environment variable OWNER_EMAIL or TF_VAR_owner_email)"
  type        = string
}

variable "environment" {
  description = "Environment name for Azure resource tags (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "resource_prefix" {
  description = "Prefix for Terraform and Confluent resource names (e.g. cjackson-)"
  type        = string
  default     = "cjackson-"
}

# Confluent Cloud (required for provider and for Kafka ACL creation on Basic cluster; use TF_VAR_* or .tfvars)
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API key for Terraform provider and Kafka ACL creation (has ALTER permission)"
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

# Admin Kafka API key used only for Terraform topic creation (Developer key is created by Terraform for apps)
variable "admin_kafka_api_key" {
  description = "Kafka API Key (Admin) for Terraform to create topics; use TF_VAR_* or .tfvars"
  type        = string
  sensitive   = true
}

variable "admin_kafka_api_secret" {
  description = "Kafka API Secret (Admin) for Terraform to create topics"
  type        = string
  sensitive   = true
}
