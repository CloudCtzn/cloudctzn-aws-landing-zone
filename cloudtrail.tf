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
        Resource = aws_s3_bucket.cloudtrail_log_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "s3:PutObject",
        Resource = [
          "${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
          "${aws_s3_bucket.cloudtrail_log_bucket.arn}/AWSLogs/${data.aws_organizations_organization.main.id}/*"
        ],
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          },
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
  is_organization_trail         = true
  include_global_service_events = true
  is_multi_region_trail         = true

  depends_on = [
    aws_s3_bucket.cloudtrail_log_bucket,
    aws_s3_bucket_policy.cloudtrail_bucket_policy,
  ]
}
