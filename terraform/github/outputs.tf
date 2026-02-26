# cjackson-: GitHub module outputs (secret names for documentation)

output "secret_names" {
  value       = ["BOOTSTRAP_SERVERS", "SCHEMA_REGISTRY_URL", "KAFKA_API_KEY", "KAFKA_API_SECRET", "TOPIC"]
  description = "Names of GitHub Actions secrets set by this module"
}
