# cjackson-: NGINX VNet and AKS module variables

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "VNet address space for NGINX VNet"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "subnet_prefix" {
  description = "Subnet address prefix for AKS"
  type        = string
  default     = "10.2.1.0/24"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = null
}

variable "node_count" {
  description = "Default node pool node count"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Environment tag for Azure resources"
  type        = string
}

variable "owner_email" {
  description = "Owner email tag for Azure resources"
  type        = string
}
