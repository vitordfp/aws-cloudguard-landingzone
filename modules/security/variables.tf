variable "cloudtrail_trail_name" {
    description = "Name of the CloudTrail trail used to capture AWS API activity across accounts."
    type        = string
    default     = "cloudguard-trail"
}

variable "log_bucket_name" {
    description = "Name of the centralized S3 bucket where CloudTrail logs will be delivered."
    type        = string
}

variable "enable_security_hub" {
    description = "Enable or disable AWS Security Hub to aggregate and prioritize security findings."
    type        = bool
    default     = true
}

variable "enable_guardduty" {
    description = "Enable or disable AWS GuardDuty for intelligent threat detection and continuous monitoring."
    type        = bool
    default     = true
}

variable "aws_region" {
    description = "AWS region where security services (CloudTrail, GuardDuty, Security Hub) will be deployed."
    type        = string
    default     = "eu-west-1"
}
