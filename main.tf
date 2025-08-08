# main.tf

# Define the required providers and their versions
# This block tells Terraform which cloud providers it needs to interact with
# and specifies a compatible version range for the AWS provider (version 5.x).
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # This ensures compatibility with AWS provider v5.x
    }
  }
  # This commented-out block is for remote state management, which we'll set up later.
  # It's a best practice to store your Terraform state file securely in S3.
   backend "s3" {
     bucket = "cloudctzn-landing-zone-tf-state" # Replace with a unique S3 bucket name
     key    = "aws-landing-zone/terraform.tfstate"
     region = "us-east-1" # Ensure this matches your desired AWS region
   }
}

# Configure the AWS provider
# This block tells Terraform which AWS region to deploy resources into.
provider "aws" {
  region = "us-east-1" # Set your desired AWS region here (e.g., us-east-1, us-west-2)
  # Terraform will use your AWS CLI configuration or environment variables
  # (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) for authentication.
}
#Resource to enable AWS Organizations 
resource "aws_organizations_organization" "main" {
	aws_server_access_principals = [
	"cloudtrail.amazonaws.com", 
	"config.amazonzws.com",
	"sso.amazonaws.com",
	"organizations.amazonaws.com"
	]
	feature_set = "ALL"
}

resource "aws_organizations.organizational_unit" "security_ou" {
	name = "Security"
	parent_id = aws_organizations_organizational_unit.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure.ou" {
	name = "Infrastructure"
	parent_id = aws_organzations_organizational_unit.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_ou" {
	name = "Workloads"
	parent_id aws_organizations_organizational_unit.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox_ou" {
	name = "Sandbox"
	parent_id aws_organizations_organizational_unit.main.roots[0].id
}
