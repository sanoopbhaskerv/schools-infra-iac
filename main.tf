provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "schools-terraform-state-1764944709"
    key            = "admin-service/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "schools-terraform-locks"
    encrypt        = true
  }
}
