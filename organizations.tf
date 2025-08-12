# Data source to fetch details of the existing AWS Organization
data "aws_organizations_organization" "main" {}

# Data source to get the caller identity for the Management Account
data "aws_caller_identity" "current" {}

# Define Organizational Units (OUs)
resource "aws_organizations_organizational_unit" "security_ou" {
  name      = "Security"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure_ou" {
  name      = "Infrastructure"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_ou" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox_ou" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.main.roots[0].id
}

# Resource to create the Log Archive Account
resource "aws_organizations_account" "log_archive" {
  name      = "Log Archive"
  email     = "z.caudle96+logarchive2@gmail.com" # <--- REPLACE WITH YOUR UNIQUE EMAIL ADDRESS
  parent_id = aws_organizations_organizational_unit.security_ou.id
  role_name = "OrganizationAccountAccessRole"
}

# Resource to create the Audit Account
resource "aws_organizations_account" "audit" {
  name      = "Audit"
  email     = "z.caudle96+audit@gmail.com" # <--- REPLACE WITH YOUR UNIQUE EMAIL ADDRESS
  parent_id = aws_organizations_organizational_unit.security_ou.id
  role_name = "OrganizationAccountAccessRole"
}

# Resource to create the Shared Services Account
resource "aws_organizations_account" "shared_services" {
  name      = "Shared Services"
  email     = "z.caudle96+sharedservices@gmail.com" # <--- REPLACE WITH YOUR UNIQUE EMAIL ADDRESS
  parent_id = aws_organizations_organizational_unit.infrastructure_ou.id
  role_name = "OrganizationAccountAccessRole"
}

# Resource to create the Workload Account
resource "aws_organizations_account" "workload" {
  name      = "Workload"
  email     = "z.caudle96+workload@gmail.com" # <--- REPLACE WITH YOUR UNIQUE EMAIL ADDRESS
  parent_id = aws_organizations_organizational_unit.workloads_ou.id
  role_name = "OrganizationAccountAccessRole"
}

# Resource to create the Sandbox Account
resource "aws_organizations_account" "sandbox" {
  name      = "Sandbox"
  email     = "z.caudle96+sandbox@gmail.com" # <--- REPLACE WITH YOUR UNIQUE EMAIL ADDRESS
  parent_id = aws_organizations_organizational_unit.sandbox_ou.id
  role_name = "OrganizationAccountAccessRole"
}

# Output the IDs of the created accounts for use in other modules/files
output "log_archive_account_id" {
  description = "The ID of the Log Archive AWS account."
  value       = aws_organizations_account.log_archive.id
}

output "audit_account_id" {
  description = "The ID of the Audit AWS account."
  value       = aws_organizations_account.audit.id
}

output "shared_services_account_id" {
  description = "The ID of the Shared Services AWS account."
  value       = aws_organizations_account.shared_services.id
}

output "workload_account_id" {
  description = "The ID of the Workload AWS account."
  value       = aws_organizations_account.workload.id
}

output "sandbox_account_id" {
  description = "The ID of the Sandbox AWS account."
  value       = aws_organizations_account.sandbox.id
}
