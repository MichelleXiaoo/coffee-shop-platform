variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "env_name" {
  type        = string
  description = "Environment name prefix, like coffee-dev"
}

variable "vpc_cidr" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  type        = string
  description = "Address to send alarm notifications to"
}