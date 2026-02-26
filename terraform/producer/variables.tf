# cjackson-: Producer VNet module variables

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "VNet address space for Producer VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_prefix" {
  description = "Subnet address prefix"
  type        = string
  default     = "10.1.1.0/24"
}
