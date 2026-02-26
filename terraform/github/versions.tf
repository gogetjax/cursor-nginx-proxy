# GitHub module: require GitHub provider (integrations/github, not hashicorp/github)
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
