terraform {
  required_providers {
    aws = {
     source  = "hashicorp/aws"
     version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    bucket       = "terraform-state"
    key          = "./terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = "terraform-lock"
    encrypt      = true
  }
}