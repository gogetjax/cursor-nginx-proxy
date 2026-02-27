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

    if not all([bootstrap, sr_url, api_key, api_secret, topic]):
        print("Set BOOTSTRAP_SERVERS, SCHEMA_REGISTRY_URL, KAFKA_API_KEY, KAFKA_API_SECRET, TOPIC", file=sys.stderr)
        sys.exit(1)

    ssl_enabled = os.environ.get("SSL_ENABLED", "true").lower() in ("true", "1", "yes")
    return {
        "bootstrap_servers": bootstrap,
        "schema_registry_url": sr_url,
        "api_key": api_key,
        "api_secret": api_secret,
        "topic": topic,
        "ssl_enabled": ssl_enabled,
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

    schema_registry_conf = {
        "url": cfg["schema_registry_url"],
        "basic.auth.user.info": f"{cfg['api_key']}:{cfg['api_secret']}",
    }

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
