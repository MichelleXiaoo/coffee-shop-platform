variable "name" {
  type        = string
  description = "Environment name prefix, e.g. coffee-dev"
}

variable "instance_id" {
  type        = string
  description = "EC2 instance to watch"
}

variable "alert_email" {
  type        = string
  description = "Address to send alarm notifications to"
}

variable "cpu_threshold" {
  type        = number
  default     = 70
  description = "Average CPU percent that triggers the alarm"
}