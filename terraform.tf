terraform {
  required_providers {
    aws = {
     source  = "hashicorp/aws"
     version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    bucket         = "${var.name_prefix}-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${var.name_prefix}-terraform-lock"
    encrypt        = true
  }
}