variable "name" {
  type = string
}

variable "enable_dynamodb_access" {
  type = bool
  default = false
  description = "Whether to attache the DynamoDB read/write polidy"
}

variable "dynamodb_table_arn" {
  type = string
  default = ""
  description = "Table ARN to scope the policy to (required when enabled)"
}