resource "aws_guardduty_detector" "this" {
    count  = var.enable_guardduty ? 1 : 0
    enable = true
}

resource "aws_securityhub_account" "this" {
    count      = var.enable_security_hub ? 1 : 0
    depends_on = [aws_guardduty_detector.this]
}

resource "aws_securityhub_standards_subscription" "this" {
    count         = var.enable_security_hub ? 1 : 0
    standards_arn = "arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0"
    depends_on    = [aws_securityhub_account.this]
}

resource "aws_cloudwatch_log_group" "trail_logs" {
    name              = "/aws/cloudtrail/${var.cloudtrail_trail_name}"
    retention_in_days = 90
    kms_key_id        = var.kms_key_id
}


resource "aws_iam_role" "cloudtrail_logs_role" {
    name = "cloudtrail-logs-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "cloudtrail.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_logs" {
    role       = aws_iam_role.cloudtrail_logs_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/CloudTrail_CloudWatchLogs_Role"
}


resource "aws_cloudtrail" "this" {
    count                         = var.enable_cloudtrail ? 1 : 0
    name                          = var.cloudtrail_trail_name
    s3_bucket_name                = var.log_bucket_name
    include_global_service_events = true
    is_multi_region_trail         = true
    enable_log_file_validation    = true
    is_organization_trail         = true
    kms_key_id                    = var.kms_key_id
    cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.trail_logs.arn
    cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_logs_role.arn
}
