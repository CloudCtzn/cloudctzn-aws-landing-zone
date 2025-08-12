# SCP: Deny Root Account Access
# This policy prevents the root user of any account its attached to
# from performing any actions, forcing the use of IAM users/roles
resource "aws_organizations_policy" "deny_root_access" {
        name = "DenyRootAccess"
        description = "Denies all actions by the root user"
        type = "SERVICE_CONTROL_POLICY"
        content = jsonencode({
           Version = "2012-10-17",
           Statement = [
                {
                  Sid = "DenyRoot",
                  Effect = "Deny",
                  Action = "*",
                  Resource = "*",
                  Condition = {
                  "StringNotLike": {
                      "aws:PrincipalArn": [
                                "arn:aws:iam::*:role/OrganizationAccountAccessRole", # Allow OrganizationAccountAccessRole
                                "arn:aws:iam::*:role/AWSControlTowerExectuion", # If using ControlTower
                                "arn:aws:iam::*:role/AWSReservedSSO_*",
                                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                                ]
                            }
                        }
                    }
                ]
            })
        }

#SCP: Restrict AWS Regions
# This policy restricts all accounts to only allow actions in specified reegions
resource "aws_organizations_policy" "restrict_regions" {
        name = "RestrictRegion"
        description = "Allows actions only in specified AWS Regions"
        type = "SERVICE_CONTROL_POLICY"
        content = jsonencode({
          Version = "2012-10-17",
          Statement = [
                {
                  Sid = "DenyAllOutsideAllowedRegions",
                  Effect = "Deny",
                  NotAction = [ # Actions that allowed globally, even outside the specified region
                        "a4b:*",
                        "aws-portal:*",
                        "budgets:*",
                        "ce:*",
                        "chime:*",
                        "cloudfront:*",
                        "config:DeleteDeliveryChannel",
                        "config:DeleteEvaluationResults",
                        "config:DeleteRetentionConfiguration",
                        "config:DeliverConfigSnapshot",
                        "config:Describe*",
                        "config:Get*",
                        "config:List*",
                        "config:Put*",
                        "config:Select*",
                        "config:StopConfigurationRecorder",
                        "directconnect:*",
                        "ec2:DescribeRegions",
                        "ec2:DescribeAvailabilityZones",
                        "globalaccelerator:*",
                        "iam:*",
                        "importexport:*",
                        "kms:DescribeKey",
                        "organizations:*",
                        "route53:*",
                        "s3:GetAccountPublicAccessBlock",
                        "s3:GetBucketLocation",
                        "s3:GetAccountPublicAccessBlock",
                        "s3:GetBucketPolicy",
                        "s3:ListAllMyBucket",
                        "s3:PutAccountPublicAccessBlock",
                        "s3:PutBucketPolicy",
                        "sso:*",
                        "support:*",
                        "sts:*",
                        "waf:*",
                        "waf-regional:*",
                        "wafv2:*"
                ],
                        Resource = "*",
                        Condition = {
                          "StringNotEquals": {
                              "aws:RequestedRegion": [
                                        "us-east-1"
                                ]
                            }
                        }
                    }
                ]
            })
        }

# Attach DenyRootAccess SCP to the Root of the Organization
resource "aws_organizations_policy_attachment" "deny_root_access_attachment" {
  policy_id = aws_organizations_policy.deny_root_access.id
  target_id = data.aws_organizations_organization.main.roots[0].id
}

# Attach RestrictRegions SCP to the Workloads OU
resource "aws_organizations_policy_attachment" "restrict_regions_workloads_attachment" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = aws_organizations_organizational_unit.workloads_ou.id
}
