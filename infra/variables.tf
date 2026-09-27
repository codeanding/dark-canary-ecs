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
  description = "CIDR allowed to reach the test listener (your public IP /32)."
  type        = string
}

variable "test_routing" {
  description = "How test traffic reaches green: \"port\" (separate :8080 listener) or \"header\" (x-dark-canary: 1 on :80)."
  type        = string
  default     = "port"

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
