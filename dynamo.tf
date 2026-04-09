# Criar a tabela do DynamoDB
resource "aws_dynamodb_table" "toggle" {
  name         = "${var.name_prefix}-dynamo-table"
  billing_mode = "PROVISIONED"
  hash_key = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  read_capacity  = 1
  write_capacity = 1
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "${var.name_prefix}-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock"
  }
}