terraform {
  required_providers {
    aws = {
     source  = "hashicorp/aws"
     version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    bucket         = "terraform-state"
    key            = "./terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}