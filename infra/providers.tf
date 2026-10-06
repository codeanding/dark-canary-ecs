provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = var.project_name
      Purpose   = "aws-community-day-demo"
      ManagedBy = "terraform"
    }
  }
}
