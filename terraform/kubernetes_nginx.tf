# cjackson-: NGINX Pod on AKS (namespace, ConfigMap, Deployment, LoadBalancer Service on 8082)

locals {
  nginx_namespace = "${var.resource_prefix}nginx"
  nginx_conf      = templatefile("${path.module}/nginx.conf.tpl", { kafka_bootstrap_host = module.confluent.kafka_bootstrap_host })
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
          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
            read_only  = true
          }
        }
        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.cjackson_nginx_conf.metadata[0].name
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
  }
}
