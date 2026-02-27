# cjackson-: Kafka ACLs for Basic cluster (topic create/describe and produce/consume)
# Credentials for creating ACLs: use Cloud API key when set (required for ACL creation); otherwise cluster API key (may 403).
locals {
  acl_credentials_key    = var.cloud_api_key != "" ? var.cloud_api_key : confluent_api_key.cjackson_kafka_api_key.id
  acl_credentials_secret = var.cloud_api_secret != "" ? var.cloud_api_secret : confluent_api_key.cjackson_kafka_api_key.secret
}

# Allow service account to create and describe topics (required for Terraform to create the topic)
resource "confluent_kafka_acl" "cjackson_sa_topic_create" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = local.acl_credentials_key
    secret = local.acl_credentials_secret
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.cjackson_sa.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
}

resource "confluent_kafka_acl" "cjackson_sa_topic_describe" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = local.acl_credentials_key
    secret = local.acl_credentials_secret
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.cjackson_sa.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
}

# Allow produce and read on topics (for Producer app)
resource "confluent_kafka_acl" "cjackson_sa_topic_write" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = local.acl_credentials_key
    secret = local.acl_credentials_secret
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.cjackson_sa.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
}

resource "confluent_kafka_acl" "cjackson_sa_topic_read" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = local.acl_credentials_key
    secret = local.acl_credentials_secret
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.cjackson_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
}

# READ on GROUP for consumer (if you consume later)
resource "confluent_kafka_acl" "cjackson_sa_group_read" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cjackson_cluster.id
  }
  rest_endpoint = data.confluent_kafka_cluster.cjackson_cluster.rest_endpoint
  credentials {
    key    = local.acl_credentials_key
    secret = local.acl_credentials_secret
  }

  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.cjackson_sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
}
