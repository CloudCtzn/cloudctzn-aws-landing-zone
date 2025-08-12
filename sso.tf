# Data source to get the ARN of the SSO instance
# This is needed to reference the enabled SSO instance in other resources.
data "aws_ssoadmin_instances" "main" {
  }

# Resource to create the Permission Set
# This defines the a set of permissions that can be assigned to users/groups in accounts.
# For now, I am creating an AdministrativeAccess Permission Set
resource "aws_ssoadmin_permission_set" "administrator_access" {
        name = "AWSAdministratorAccess"
        instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0] # References the SSO instance arn
        description = "Provides full access to AWS services and resources"
        session_duration = "PT8H"

        depends_on = [
                data.aws_ssoadmin_instances.main
        ]
  }

# Resource to attach a managed policy to the permission set
resource "aws_ssoadmin_managed_policy_attachment" "administrator_access_attachment" {
        instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
        managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"



        depends_on = [
            aws_ssoadmin_permission_set.administrator_access
        ]
 }

# Assign AWSAdministratorAccess permission set to the Log Archive Account
resource "aws_ssoadmin_account_assignment" "log_archive_admin_assignment" {
        instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
        target_id = var.log_archive_account_id
        principal_type = "GROUP"
        principal_id = "2458a468-f061-707b-daaa-2242295c93dc"
        target_type = "AWS_ACCOUNT"
 }

# Assign AWSAdministratorAccess permission set to the Audit Account
resource "aws_ssoadmin_account_assignment" "audit_admin_assignment" {
        instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
        target_id = var.audit_account_id
        principal_type = "GROUP"
        principal_id = "2458a468-f061-707b-daaa-2242295c93dc"
        target_type = "AWS_ACCOUNT"
 }

# Assign AWSAdministratorAccess permission set to the Shared Services Account
resource "aws_ssoadmin_account_assignment" "shared_services_admin_assignment" {
        instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
        target_id = var.shared_services_account_id
        principal_type = "GROUP"
        principal_id = "2458a468-f061-707b-daaa-2242295c93dc"
        target_type = "AWS_ACCOUNT"
 }

# Assign AWSAdministratorAccess permission set to the Workload Account
resource "aws_ssoadmin_account_assignment" "workload_admin_assignment" {
        instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
        target_id = var.workload_account_id
        principal_type = "GROUP"
        principal_id = "2458a468-f061-707b-daaa-2242295c93dc"
        target_type = "AWS_ACCOUNT"
 }

# Assign AWSAdministratorAccess permission set to Sandbox Account
resource "aws_ssoadmin_account_assignment" "sandbox_admin_assignment" {
        instance_arn = tolist(data.aws_ssoadmin_instances.main.arns)[0]
        permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
        target_id = var.sandbox_account_id
        principal_type = "GROUP"
        principal_id = "2458a468-f061-707b-daaa-2242295c93dc"
        target_type = "AWS_ACCOUNT"
 }

