output "guardduty_detector_id" {
    description = "ID of the GuardDuty detector"
    value       = aws_guardduty_detector.this.id
}

output "cloudtrail_arn" {
    description = "ARN of the CloudTrail trail"
    value       = aws_cloudtrail.this.arn
}

output "securityhub_admin_account" {
    description = "The Security Hub admin account ID"
    value       = aws_securityhub_account.this.account_id
}

output "cloudtrail_log_bucket_name" {
    description = "Name of the S3 bucket where CloudTrail logs are delivered"
    value       = var.log_bucket_name
}

output "securityhub_standards_arn" {
    description = "ARN of the Security Hub standards subscription"
    value       = aws_securityhub_standards_subscription.this.standards_arn
}
