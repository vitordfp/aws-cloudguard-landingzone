package policy.deny_global_services

import future.keywords

# Mock SCP to test
scp := {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyGlobalDescribeList",
            "Effect": "Deny",
            "Action": [
                "ec2:Describe*",
                "iam:List*"
            ],
            "Resource": "*"
        }
    ]
}

# Helper function to check if action matches any pattern
action_matches(patterns, action) if {
    some p in patterns
    endswith(p, "*")
    startswith(action, trim_suffix(p, "*"))
} else if {
    action == patterns[_]
}

test_deny_ec2_describe if {
    some stmt in scp.Statement
    stmt.Effect == "Deny"
    action_matches(stmt.Action, "ec2:DescribeInstances")
}

test_deny_iam_list if {
    some stmt in scp.Statement
    stmt.Effect == "Deny"
    action_matches(stmt.Action, "iam:ListUsers")
}

allow_s3_putobject if {
    some stmt in scp.Statement
    action_matches(stmt.Action, "s3:PutObject")
}

test_allow_other_actions if {
    not allow_s3_putobject
}
