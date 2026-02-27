#!/usr/bin/env bash
# Build (plan + apply) cursor-nginx-proxy Terraform stack.
# Set required variables via TF_VAR_* or a terraform.tfvars file (see terraform.tfvars.example).

set -e
cd "$(dirname "$0")"

REQUIRED_VARS="azure_subscription_id azure_tenant_id owner_email github_owner"
MISSING=""
for v in $REQUIRED_VARS; do
  if [ -z "${TF_VAR_$v}" ] && ! grep -q "^$v\s*=" terraform.tfvars 2>/dev/null; then
    MISSING="$MISSING $v"
  fi
done
if [ -n "$MISSING" ]; then
  echo "Missing required variable(s). Set via TF_VAR_<name> or in terraform.tfvars:${MISSING}"
  echo "Example: export TF_VAR_owner_email=you@example.com"
  echo "See terraform.tfvars.example for all variables."
  exit 1
fi

terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -input=false tfplan
