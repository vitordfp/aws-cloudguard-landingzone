package security

test_cloudtrail_unencrypted_is_denied {
    deny_cloudtrail_unencrypted with input as {
        "resource_type": "aws_cloudtrail",
        "encrypted": false
    }
}

test_cloudtrail_encrypted_is_allowed {
    not deny_cloudtrail_unencrypted with input as {
        "resource_type": "aws_cloudtrail",
        "encrypted": true
    }
}

test_guardduty_disabled_is_denied {
    deny_missing_guardduty with input as {
        "resource_type": "aws_guardduty_detector",
        "enable": false
    }
}
