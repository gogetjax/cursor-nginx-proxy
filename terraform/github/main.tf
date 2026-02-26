# cjackson-: Push Terraform outputs to GitHub Actions secrets (for Producer and workflows)

# Only create secrets when values are non-empty (e.g. after first apply when LB is ready)
resource "github_actions_secret" "bootstrap_servers" {
  count           = var.bootstrap_servers != "" ? 1 : 0
  repository      = var.repository
  secret_name     = "BOOTSTRAP_SERVERS"
  plaintext_value = var.bootstrap_servers
}

resource "github_actions_secret" "schema_registry_url" {
  count           = var.schema_registry_url != "" ? 1 : 0
  repository      = var.repository
  secret_name     = "SCHEMA_REGISTRY_URL"
  plaintext_value = var.schema_registry_url
}

resource "github_actions_secret" "kafka_api_key" {
  count           = var.kafka_api_key != "" ? 1 : 0
  repository      = var.repository
  secret_name     = "KAFKA_API_KEY"
  plaintext_value = var.kafka_api_key
}

resource "github_actions_secret" "kafka_api_secret" {
  count           = var.kafka_api_secret != "" ? 1 : 0
  repository      = var.repository
  secret_name     = "KAFKA_API_SECRET"
  plaintext_value = var.kafka_api_secret
}

resource "github_actions_secret" "topic_name" {
  count           = var.topic_name != "" ? 1 : 0
  repository      = var.repository
  secret_name     = "TOPIC"
  plaintext_value = var.topic_name
}
