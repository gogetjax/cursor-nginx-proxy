# cjackson-: NGINX module outputs (for Kubernetes provider and Load Balancer URL)

output "aks_name" {
  value = azurerm_kubernetes_cluster.cjackson_nginx.name
}

output "aks_rg" {
  value = azurerm_resource_group.cjackson_nginx.name
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.cjackson_nginx.kube_config_raw
  sensitive = true
}

output "aks_host" {
  value = azurerm_kubernetes_cluster.cjackson_nginx.kube_config[0].host
}

output "aks_client_certificate" {
  value     = azurerm_kubernetes_cluster.cjackson_nginx.kube_config[0].client_certificate
  sensitive = true
}

output "aks_client_key" {
  value     = azurerm_kubernetes_cluster.cjackson_nginx.kube_config[0].client_key
  sensitive = true
}

output "aks_cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.cjackson_nginx.kube_config[0].cluster_ca_certificate
  sensitive = true
}
