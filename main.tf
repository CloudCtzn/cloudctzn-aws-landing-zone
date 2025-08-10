# main.tf

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

# Define a variable for the AWS region to use in policies
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1" # <--- ENSURE THIS MATCHES YOUR AWS REGION
}

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

# Resource to create an S3 bucket for CloudTrail logs in the Log Archive account
resource "aws_s3_bucket" "cloudtrail_log_bucket" {
  bucket = "cloudctzn-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "CloudCtzn-CloudTrail-Logs"
    Environment = "LandingZone"
  }
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_log_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.cloudtrail_log_bucket.arn # Correct for bucket ACL check
      },
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:PutObject",
        # This Resource ARN must be a list for organization trails
        # It covers logs from the Management Account and Organization members
        Resource = [
          "${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*", # For logs from Management Account
          "${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSLogs/${data.aws_organizations_organization.main.id}/*" # For logs from Organization members
        ],
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          },
          # This condition is crucial for organization trails to restrict writes to specific CloudTrail ARNs
          "ArnLike": {
            "aws:SourceArn": [
              "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/*",
              "arn:aws:cloudtrail:${var.aws_region}:${data.aws_organizations_organization.main.id}:trail/*"
            ]
          }
        }
      }
    ]
  })
}

# Resource to create an Organization Trail in CloudTrail
resource "aws_cloudtrail" "organization_trail" {
  name                          = "CloudCtzn-Organization-Trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_log_bucket.id
  is_organization_trail         = true # This argument makes it organization-wide
  include_global_service_events = true
  is_multi_region_trail         = true

  depends_on = [
    aws_s3_bucket.cloudtrail_log_bucket,
    aws_s3_bucket_policy.cloudtrail_bucket_policy,
  ]
}

# IAM Role for AWS Config
# This role grants AWS Config the necessary permissions to record resource configurations
# and deliver them to my S3 bucket and SNS topic (if its configured) 
resource "aws_iam_role" "config_recorder_role" {
  name = "CloudCtzn-ConfigRecorderRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
	{
	  Action = "sts:AssumeRole",
	  Effect = "Allow"
	  Sid = "",
	  Principal = {
		Service = "config.amazonaws.com"
		}
	   }
	]
    })

	tags = {
	name = "CloudCtzn-ConfigRecorderRole"
	Environment = "LandingZone"
	}
    }


# IAM Policy for AWS Config Role
# This policy generates permissons to read resource configurations,
# deliver logs to S3, and publish to SNS.
resource "aws_iam_role_policy" "config_recorder_policy" {
  name = "CloudCtzn-ConfigRecorderPolicy"
  role = aws_iam_role.config_recorder_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketAcl"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSConfig/*", # For objects within the AWSConfig prefix
          aws_s3_bucket.cloudtrail_log_bucket.arn # For the bucket itself (needed for GetBucketAcl)
        ]
      },
      {
        Action = "s3:GetBucketLocation",
        Effect = "Allow",
        Resource = aws_s3_bucket.cloudtrail_log_bucket.arn
      },
      {
        Action = [
          "config:PutConfigurationRecorder",
          "config:PutDeliveryChannel",
          "config:StartConfigurationRecorder",
          "config:StopConfigurationRecorder",
          "config:Get*",
          "config:List*",
          "config:Describe*"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "iam:GetRole",
          "iam:PassRole"
        ],
        Effect = "Allow",
        Resource = aws_iam_role.config_recorder_role.arn
      },
      {
        Action = "ec2:Describe*",
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = "cloudwatch:PutMetricData",
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}


# AWS Config Configuration Recorder
# This records configuration changes for all supported resources in the region.
resource "aws_config_configuration_recorder" "recorder" {
	name = "CloudCtzn-ConfigRecorder"
	role_arn = aws_iam_role.config_recorder_role.arn

	# Records all resource types 
	recording_group {
	  all_supported = true
	  include_global_resource_types = true
	}

	depends_on = [
	  aws_iam_role_policy.config_recorder_policy # Ensures policy is attached before recorder is created 
	]
    }

# AWS Config Delivery Channel 
# This specifies where AWS Config will send its configuration snapshots and history.
resource "aws_config_delivery_channel" "delivery_channel" {
	name = "CloudCtzn_ConfigDeliveryChannel"
	s3_bucket_name = aws_s3_bucket.cloudtrail_log_bucket.id # Reusing the S3 CloudTrail bucket 
	s3_key_prefix = "AWSConfig" # Store Config Logs under a separate prefix in the bucket 

	depends_on = [
	  aws_config_configuration_recorder.recorder # Ensures recorder is setup first
	]
    }

# AWS Config Rule: Check if S3 buckets are public
# This rule examines whether S3 buckets pubicly acessible. 
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
	name = "s3-bucket-public-read-prohibited"
	description = "Checks if S3 buckets are pubicly readable. Non-compliant is public read access is granted."
	source { 
	  owner = "AWS"
	  source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
	}
	scope {
	   compliance_resource_types = ["AWS::S3::Bucket"]
	}

	depends_on = [
	  aws_config_configuration_recorder.recorder,
	  aws_config_delivery_channel.delivery_channel # Ensure Config is recording and watching
	]
    }

# Start the Config Recorder after everything is set up
resource "null_resource" "start_config_recorder" {
	triggers = {
		always_run = timestamp() # Ensures this runs on every apply 
	}
	provisioner "local-exec" {
		command = "aws configservice start-configuration-recorder --configuration-recorder-name ${aws_config_configuration_recorder.recorder.name}"
		interpreter = ["bash", "-c"]
	}

	depends_on = [
		aws_config_delivery_channel.delivery_channel,
		aws_config_configuration_recorder.recorder
	]
    }
