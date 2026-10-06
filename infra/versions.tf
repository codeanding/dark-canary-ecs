terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Native ECS blue/green needs >= 6.4; the demo is tested with 6.66 (see .terraform.lock.hcl).
      version = "~> 6.66"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}
