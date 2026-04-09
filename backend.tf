# backend para salvar o state do Terraform no S3 bucket
terraform {
  backend "s3" {
    bucket         = "${var.name_prefix}-terraform-state"
    key            = "./terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${var.name_prefix}-terraform-locks"
    encrypt        = true
  }
}