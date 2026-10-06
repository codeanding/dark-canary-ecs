variable "aws_region" {
  description = "AWS region for the whole demo."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile for Terraform. null = use AWS_PROFILE from the environment (scripts/env.sh sets it)."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Prefix for every resource name (ALB, target groups, cluster, Lambdas, bucket)."
  type        = string
  default     = "dark-canary"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.project_name))
    error_message = "Lowercase letters, digits and hyphens, max 20 characters (ALB and target group names are limited to 32)."
  }
}

variable "presenter_cidr" {
  description = "Your public IP as /32. Only this IP and the NAT EIP (hook Lambdas) can reach green, in either routing mode."
  type        = string
  sensitive   = true

  validation {
    condition     = can(cidrhost(var.presenter_cidr, 0)) && endswith(var.presenter_cidr, "/32")
    error_message = "presenter_cidr must be a single IPv4 address in /32 notation, e.g. 203.0.113.10/32."
  }
}

variable "test_routing" {
  description = "How test traffic reaches green: \"header\" (x-dark-canary: 1 on :80, default) or \"port\" (separate :8080 listener)."
  type        = string
  default     = "header"

  validation {
    condition     = contains(["port", "header"], var.test_routing)
    error_message = "test_routing must be \"port\" or \"header\"."
  }
}

variable "app_image_tag" {
  description = "Image tag for the initial task definition. Later deploys go through scripts/deploy.sh."
  type        = string
  default     = "v1"
}

variable "app_port" {
  description = "Port the app container listens on."
  type        = number
  default     = 3000

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "pause_before_production" {
  description = "Adds a PAUSE hook at POST_TEST_TRAFFIC_SHIFT; continue it with scripts/continue.sh."
  type        = bool
  default     = true
}
