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

resource "aws_cloudtrail" "this" {
    name                          = var.cloudtrail_trail_name
    s3_bucket_name                = var.log_bucket_name
    include_global_service_events = true
    is_multi_region_trail         = true
    enable_log_file_validation    = true
    is_organization_trail         = true
}
