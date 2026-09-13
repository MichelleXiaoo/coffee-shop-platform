variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "env_name" {
  type        = string
  description = "Environment name prefix, like coffee-dev"
}

variable "vap_cidr" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
