# cjackson-: NGINX stream proxy (Kafka 8082) + HTTPS reverse proxy (Schema Registry 8443)
# Stream: TLS passthrough to Confluent Kafka. Http: reverse proxy to Confluent Schema Registry with Terraform-generated TLS cert.

stream {
  server {
    listen 8082;
    proxy_pass ${kafka_bootstrap_host};
    proxy_connect_timeout 10s;
    proxy_timeout 3600s;
    proxy_buffer_size 16k;
  }
}

http {
  resolver 8.8.8.8;
  server {
    listen 8443 ssl;
    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    location / {
      proxy_pass ${schema_registry_url}$request_uri;
      proxy_set_header Host ${schema_registry_host};
      proxy_ssl_server_name on;
      proxy_ssl_name ${schema_registry_host};
      proxy_set_header X-Forwarded-Proto $scheme;
    }
  }
}

events {
  worker_connections 1024;
}
