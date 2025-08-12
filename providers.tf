# Define the required providers and their versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "cloudctzn-landing-zone-tf-state" # <--- REPLACE WITH YOUR UNIQUE BUCKET NAME
    key    = "aws-landing-zone/terraform.tfstate"
    region = "us-east-1" # <--- ENSURE THIS MATCHES YOUR AWS REGION
  }
}

# Configure the AWS provider
provider "aws" {
  region = "us-east-1" # <--- ENSURE THIS MATCHES YOUR AWS REGION
}
