# cjackson-: NGINX Pod on AKS (namespace, ConfigMap, Deployment, LoadBalancer Service on 8082 + 8443)
# TLS cert for Schema Registry HTTPS (8443) is Terraform-generated so tear-down/rebuild is automatic.

locals {
  nginx_namespace       = "${var.resource_prefix}nginx"
  sr_url_no_scheme      = replace(replace(module.confluent.schema_registry_url, "https://", ""), "http://", "")
  schema_registry_host  = regex("^[^/]+", local.sr_url_no_scheme)
  nginx_conf            = templatefile("${path.module}/nginx.conf.tpl", {
    kafka_bootstrap_host  = module.confluent.kafka_bootstrap_host
    schema_registry_url   = module.confluent.schema_registry_url
    schema_registry_host  = local.schema_registry_host
  })
}

# Terraform-generated self-signed cert for NGINX Schema Registry listener (8443)
resource "tls_private_key" "nginx_sr" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "nginx_sr" {
  private_key_pem = tls_private_key.nginx_sr.private_key_pem
  subject {
    common_name = "nginx-schema-registry"
  }
  validity_period_hours = 8760 # 1 year
  allowed_uses          = ["server_auth"]
}

resource "kubernetes_namespace" "cjackson_nginx" {
  metadata {
    name = local.nginx_namespace
  }
}

resource "kubernetes_config_map" "cjackson_nginx_conf" {
  metadata {
    name      = "nginx-conf"
    namespace = kubernetes_namespace.cjackson_nginx.metadata[0].name
  }
  data = {
    "nginx.conf" = local.nginx_conf
  }
}

resource "kubernetes_secret" "cjackson_nginx_sr_tls" {
  metadata {
    name      = "nginx-sr-tls"
    namespace = kubernetes_namespace.cjackson_nginx.metadata[0].name
  }
  data = {
    "cert.pem" = tls_self_signed_cert.nginx_sr.cert_pem
    "key.pem"  = tls_private_key.nginx_sr.private_key_pem
  }
  type = "Opaque"
}

resource "kubernetes_deployment" "cjackson_nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.cjackson_nginx.metadata[0].name
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "nginx" }
    }
    template {
      metadata {
        labels = { app = "nginx" }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"
          port {
            container_port = 8082
          }
          port {
            container_port = 8443
          }
          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
            read_only  = true
          }
          volume_mount {
            name       = "nginx-ssl"
            mount_path = "/etc/nginx/ssl"
            read_only  = true
          }
        }
        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.cjackson_nginx_conf.metadata[0].name
          }
        }
        volume {
          name = "nginx-ssl"
          secret {
            secret_name = kubernetes_secret.cjackson_nginx_sr_tls.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "cjackson_nginx_lb" {
  metadata {
    name      = "nginx-lb"
    namespace = kubernetes_namespace.cjackson_nginx.metadata[0].name
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = kubernetes_deployment.cjackson_nginx.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 8082
      target_port = 8082
      protocol    = "TCP"
      name        = "kafka"
    }
    port {
      port        = 8443
      target_port = 8443
      protocol    = "TCP"
      name        = "schema-registry"
    }
  }
}
