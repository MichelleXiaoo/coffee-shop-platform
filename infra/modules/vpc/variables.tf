variable "name" {
  type        = string
  description = "coffee-dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = string
  default = 2
}

