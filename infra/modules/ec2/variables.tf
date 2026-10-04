variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type = number
  default = 80
  description = "Port the app listens on"
}

variable "allowed_http_cidrs" {
  type = list(string)
  default = []
  description = "CIDRs allowed inbound to app_port. Empty list = no inbound (secure default)."
}

variable "enable_monitoring" {
  type        = bool
  default     = false
  description = "Run node_exporter, Prometheus and Grafana on the instance"
}

variable "grafana_admin_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Grafana admin password. Only used when enable_monitoring is true."
}