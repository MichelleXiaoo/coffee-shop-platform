resource "aws_dynamodb_table" "orders" {
  name = "${var.name}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "order_id"

# Only key/indexed attributes are declared - DynamoDB is schemaless
# For everything else (customer, item, created_at are written at runtime)
  attribute {
    name = "order_id"
    type = "S"
  }

  tags = { Name = "${var.name}-orders"}
}