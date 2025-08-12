# Define a variable for the AWS region to use in policies
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1" # <--- ENSURE THIS MATCHES YOUR AWS REGION
}
