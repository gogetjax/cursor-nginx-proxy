#!/usr/bin/env python3
"""
Kafka producer that sends sample data to a topic via the NGINX proxy (TLS to NGINX:8082).
Uses Confluent Schema Registry from env. All configuration from environment variables.
"""
import os
import sys
import json
from datetime import datetime, timezone

from confluent_kafka import Producer
from confluent_kafka.serialization import MessageField, SerializationContext, StringSerializer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.json_schema import JSONSerializer


def load_env():
    """Load required config from environment (or .env via python-dotenv)."""
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass

    bootstrap = os.environ.get("BOOTSTRAP_SERVERS")
    sr_url = os.environ.get("SCHEMA_REGISTRY_URL")
    api_key = os.environ.get("KAFKA_API_KEY")
    api_secret = os.environ.get("KAFKA_API_SECRET")
    topic = os.environ.get("TOPIC")
    sr_ca_cert = os.environ.get("SCHEMA_REGISTRY_CA_CERT")
    sr_api_key = os.environ.get("SCHEMA_REGISTRY_API_KEY")
    sr_api_secret = os.environ.get("SCHEMA_REGISTRY_API_SECRET")
    kafka_ssl_ca_location = os.environ.get("KAFKA_SSL_CA_LOCATION")
    kafka_ssl_verify_hostname = os.environ.get("KAFKA_SSL_VERIFY_HOSTNAME", "true").lower() in ("true", "1", "yes")

    if not all([bootstrap, sr_url, api_key, api_secret, topic]):
        print("Set BOOTSTRAP_SERVERS, SCHEMA_REGISTRY_URL, KAFKA_API_KEY, KAFKA_API_SECRET, TOPIC", file=sys.stderr)
        sys.exit(1)

    # When using Schema Registry via NGINX (port 8443), self-signed cert requires CA file
    if sr_url and ":8443" in sr_url and not sr_ca_cert:
        print(
            "SCHEMA_REGISTRY_CA_CERT is required when using Schema Registry via NGINX (port 8443). "
            "Export the cert from the nginx-sr-tls secret and set SCHEMA_REGISTRY_CA_CERT to its path. "
            "See README for /etc/hosts and curl test steps.",
            file=sys.stderr,
        )
        sys.exit(1)

    ssl_enabled = os.environ.get("SSL_ENABLED", "true").lower() in ("true", "1", "yes")
    return {
        "bootstrap_servers": bootstrap,
        "schema_registry_url": sr_url,
        "api_key": api_key,
        "api_secret": api_secret,
        "topic": topic,
        "ssl_enabled": ssl_enabled,
        "schema_registry_ca_cert": sr_ca_cert,
        "schema_registry_api_key": sr_api_key,
        "schema_registry_api_secret": sr_api_secret,
        "kafka_ssl_ca_location": kafka_ssl_ca_location,
        "kafka_ssl_verify_hostname": kafka_ssl_verify_hostname,
    }


def main():
    cfg = load_env()

    # Producer config: TLS to NGINX (bootstrap = NGINX LB:8082), SASL for Confluent
    producer_conf = {
        "bootstrap.servers": cfg["bootstrap_servers"],
        "security.protocol": "SASL_SSL",
        "sasl.mechanisms": "PLAIN",
        "sasl.username": cfg["api_key"],
        "sasl.password": cfg["api_secret"],
    }
    if cfg.get("kafka_ssl_ca_location"):
        producer_conf["ssl.ca.location"] = cfg["kafka_ssl_ca_location"]
    if not cfg.get("kafka_ssl_verify_hostname", True):
        producer_conf["ssl.endpoint.identification.algorithm"] = ""

    # Use dedicated SR API key when both set (avoids 401 when SR is via NGINX); else Kafka key
    sr_user = cfg["api_key"]
    sr_pass = cfg["api_secret"]
    if cfg.get("schema_registry_api_key") and cfg.get("schema_registry_api_secret"):
        sr_user = cfg["schema_registry_api_key"]
        sr_pass = cfg["schema_registry_api_secret"]
    schema_registry_conf = {
        "url": cfg["schema_registry_url"],
        "basic.auth.user.info": f"{sr_user}:{sr_pass}",
    }
    if cfg.get("schema_registry_ca_cert"):
        schema_registry_conf["ssl.ca.location"] = cfg["schema_registry_ca_cert"]

    sr_client = SchemaRegistryClient(schema_registry_conf)

    # JSON Schema (Schema Registry) for sample records
    value_schema = """{
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "title": "SampleEvent",
      "type": "object",
      "properties": {
        "id": { "type": "string" },
        "timestamp": { "type": "string" },
        "message": { "type": "string" }
      }
    }"""

    json_serializer = JSONSerializer(value_schema, sr_client)

    producer = Producer(producer_conf)

    def delivery_cb(err, msg):
        if err:
            print(f"Delivery failed: {err}", file=sys.stderr)
        else:
            print(f"Produced to {msg.topic()} partition {msg.partition()} offset {msg.offset()}")

    # Produce a few sample records
    for i in range(5):
        value = {
            "id": f"sample-{i}",
            "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "message": f"Sample message #{i} via NGINX proxy",
        }
        producer.produce(
            topic=cfg["topic"],
            value=json_serializer(value, SerializationContext(cfg["topic"], MessageField.VALUE)),
            key=StringSerializer("utf-8")(f"key-{i}", SerializationContext(cfg["topic"], MessageField.KEY)),
            callback=delivery_cb,
        )

    producer.flush()
    print("Done.")


if __name__ == "__main__":
    main()
