package security

deny_cloudtrail_unencrypted {
    input.resource_type == "aws_cloudtrail"
    not input.encrypted
}

deny_missing_guardduty {
    input.resource_type == "aws_guardduty_detector"
    input.enable != true
}
