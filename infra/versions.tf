terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Native ECS blue/green (strategy, lifecycle_hook, advanced_configuration) needs >= 6.4.
      version = "~> 6.4"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}
