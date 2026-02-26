# cjackson-: Provider configuration (Azure, Kubernetes from AKS)

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
  features {}
}

# Kubernetes provider configured from NGINX module AKS output (must apply nginx module first)
provider "kubernetes" {
  host                   = module.nginx.aks_host
  client_certificate     = base64decode(module.nginx.aks_client_certificate)
  client_key             = base64decode(module.nginx.aks_client_key)
  cluster_ca_certificate = base64decode(module.nginx.aks_cluster_ca_certificate)
}

# GitHub provider (optional; set github_token when managing repo/secrets)
provider "github" {
  owner = var.github_owner
  token = var.github_token
}
