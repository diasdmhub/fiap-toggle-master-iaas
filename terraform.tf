# definição do provider
terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
     source  = "hashicorp/aws"
     version = "~> 5.92"
    }
  }

# backend remoto no S3 bucket da AWS
  backend "s3" {
    bucket         = "fiap-toggle-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fiap-toggle-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}