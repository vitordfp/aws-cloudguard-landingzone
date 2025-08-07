# Security Module

This Terraform module provisions centralized AWS security services across an organization, including:

- **AWS GuardDuty** – intelligent threat detection and continuous monitoring  
- **AWS Security Hub** – aggregated security findings across accounts  
- **AWS CloudTrail** – centralized audit trail for API activity  

It is designed to be used within an AWS Organization and supports organization-wide deployments.

---

## ✅ Features

- Enables GuardDuty detector
- Enables Security Hub and foundational security best practices standard
- Creates a centralized CloudTrail across all regions
- Integrates with existing S3 log bucket

---

## 📥 Inputs

| Name                | Description                                                              | Type   | Default             |
|---------------------|--------------------------------------------------------------------------|--------|---------------------|
| `cloudtrail_trail_name` | Name for the CloudTrail trail                                           | string | `cloudguard-trail`  |
| `log_bucket_name`       | Name of the centralized S3 bucket for CloudTrail logs                 | string | n/a *(required)*    |
| `enable_security_hub`   | Whether to enable Security Hub                                        | bool   | `true`              |
| `enable_guardduty`      | Whether to enable GuardDuty                                           | bool   | `true`              |
| `aws_region`            | AWS Region where resources will be created                            | string | `eu-west-1`         |

---

## 📤 Outputs

| Name                    | Description                               |
|-------------------------|-------------------------------------------|
| `guardduty_detector_id` | ID of the GuardDuty detector              |
| `cloudtrail_arn`        | ARN of the CloudTrail                     |
| `securityhub_admin_account` | Account ID registered with Security Hub  |

---

## 🧪 Policy Testing

This module is tested using [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) policies.  
Rego policy and test files can be found in the `tests/` subfolder:

```bash
modules/security/tests/
├── policy.rego
└── policy_test.rego

GitHub Actions will run these tests automatically for every pull request.


📌 Example Usage

module "security" {
  source            = "../../modules/security"
  log_bucket_name   = "central-logs-bucket"
  aws_region        = "eu-west-1"
}

🛡️ Notes
Ensure the log_bucket_name points to a pre-existing S3 bucket with appropriate permissions.

This module is designed for use within an AWS Organization with CloudTrail enabled org-wide.