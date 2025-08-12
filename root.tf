# This file defines the input variables for the root module.
# These variables will be populated by terraform.tfvars.

variable "log_archive_account_id" {
  description = "The ID of the Log Archive AWS account."
  type        = string
}

variable "audit_account_id" {
  description = "The ID of the Audit AWS account."
  type        = string
}

variable "shared_services_account_id" {
  description = "The ID of the Shared Services AWS account."
  type        = string
}

variable "workload_account_id" {
  description = "The ID of the Workload AWS account."
  type        = string
}

variable "sandbox_account_id" {
  description = "The ID of the Sandbox AWS account."
  type        = string
}
