# cjackson-: NGINX stream proxy – TLS passthrough to Confluent Kafka bootstrap (port 9092)
# Listens on 8082; forwards TCP to Kafka without decrypting TLS (ngx_stream_proxy_module)

stream {
  server {
    listen 8082;
    proxy_pass ${kafka_bootstrap_host};
    proxy_connect_timeout 10s;
    proxy_timeout 3600s;
    proxy_buffer_size 16k;
  }
}

events {
  worker_connections 1024;
}
