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

variable "instnace_type" {
  type    = string
  default = "t3.micro"
}

