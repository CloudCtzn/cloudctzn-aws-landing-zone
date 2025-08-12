# IAM Role for AWS Config
resource "aws_iam_role" "config_recorder_role" {
  name = "CloudCtzn-ConfigRecorderRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "CloudCtzn-ConfigRecorderRole"
    Environment = "LandingZone"
  }
}

# IAM Policy for AWS Config Role
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
          "${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSConfig/*",
          aws_s3_bucket.cloudtrail_log_bucket.arn
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
resource "aws_config_configuration_recorder" "recorder" {
  name     = "CloudCtzn-ConfigRecorder"
  role_arn = aws_iam_role.config_recorder_role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }

  depends_on = [
    aws_iam_role_policy.config_recorder_policy
  ]
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "CloudCtzn-ConfigDeliveryChannel"
  s3_bucket_name = aws_s3_bucket.cloudtrail_log_bucket.id
  s3_key_prefix  = "AWSConfig"

  depends_on = [
    aws_config_configuration_recorder.recorder
  ]
}

# AWS Config Rule: Check if S3 buckets are public (example)
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name        = "s3-bucket-public-read-prohibited"
  description = "Checks if S3 buckets are publicly readable. Non-compliant if public read access is granted."
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  depends_on = [
    aws_config_configuration_recorder.recorder,
    aws_config_delivery_channel.delivery_channel
  ]
}

# AWS Config Rule: Ensure all S3 buckets are encrypted
resource "aws_config_config_rule" "s3_bucket_encrypted" {
  name        = "s3-bucket-encrypted"
  description = "Checks if S3 buckets have server-side encryption enabled. Non-compliant if not enabled."
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  depends_on = [
    aws_config_configuration_recorder.recorder,
    aws_config_delivery_channel.delivery_channel
  ]
}

# AWS Config Rule: Check if MFA is enabled for the Root account
resource "aws_config_config_rule" "root_account_mfa_enabled" {
  name        = "root-account-mfa-enabled"
  description = "Checks whether the root account has multi-factor authentication (MFA) enabled. Non-compliant if MFA is not enabled."
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
  scope {
    compliance_resource_types = ["AWS::IAM::User"]
  }

  depends_on = [
    aws_config_configuration_recorder.recorder,
    aws_config_delivery_channel.delivery_channel
  ]
}

# AWS Config Rule: Ensure EC2 instances are not publicly accessible
resource "aws_config_config_rule" "ec2_instance_no_public_ip" {
  name        = "ec2-instance-no-public-ip"
  description = "Checks whether running EC2 instances have a public IP address. Non-compliant if a public IP is assigned."
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }
  scope {
    compliance_resource_types = ["AWS::EC2::Instance"]
  }

  depends_on = [
    aws_config_configuration_recorder.recorder,
    aws_config_delivery_channel.delivery_channel
  ]
}
