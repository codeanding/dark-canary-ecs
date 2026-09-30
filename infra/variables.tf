variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "aws_profile" {
  type    = string
  default = "codeanding"
}

variable "project_name" {
  type    = string
  default = "dark-canary"
}

variable "presenter_cidr" {
  description = "Your public IP /32. Only this IP and the NAT EIP (hook Lambdas) can reach green, in either routing mode."
  type        = string
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
  type    = number
  default = 3000
}

variable "pause_before_production" {
  description = "Adds a PAUSE hook at POST_TEST_TRAFFIC_SHIFT; continue it with scripts/continue.sh."
  type        = bool
  default     = true
}
