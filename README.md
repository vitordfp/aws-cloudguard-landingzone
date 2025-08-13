# 🛡️ AWS CloudGuard Landing Zone

This repository provides a modular and secure AWS Landing Zone setup using Terraform. It follows AWS best practices for managing multi-account environments with infrastructure-as-code and GitHub Actions for CI/CD.

---

## 📁 Project Structure
|── .github/workflows # CI/CD workflows (plan, apply, security scans)
|── environments/ # Environment-specific Terraform configurations (e.g., dev, prod)
|── modules/ # Reusable Terraform modules (org, network, security, visionguard-s3)
|── scripts/ # Utility scripts (bootstrap, cleanup)
|── docs/ # Documentation (architecture, usage)


---

## 🧱 Modules

- **org**: AWS Organizations, OUs, and Service Control Policies (SCPs)
- **network**: Hub-and-spoke VPC architecture using Transit Gateway
- **security**: GuardDuty, Security Hub, and CloudTrail configuration
- **visionguard-s3**: Serverless image scanning pipeline using Lambda and Rekognition

---

## 🚀 CI/CD Workflows

- `terraform-plan.yml`: Runs `terraform fmt`, `init`, and `plan` on pull requests
- `terraform-apply.yml`: Applies infrastructure changes with manual approval
- `security-scans.yml`: Executes `tfsec` and OPA policy validation

---

## ✅ Getting Started

```bash
git clone https://github.com/YOUR-ORG/aws-cloudguard-landingzone.git
cd environments/dev
terraform init
terraform plan



# Security Module

This module enables key AWS security services:

- **Amazon GuardDuty**
- **AWS Security Hub**
- **AWS CloudTrail**

## Enabled Services & Resources

### 🛡️ GuardDuty
Enables intelligent threat detection and continuous monitoring.

- [Terraform aws_guardduty_detector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector)

### 🧩 Security Hub
Aggregates security findings and supports compliance standards.

- [Terraform aws_securityhub_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account)
- [Terraform aws_securityhub_standards_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription)

### 📜 CloudTrail
Records account activity and API usage across AWS infrastructure.

- [Terraform aws_cloudtrail](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail)

---




---

## 🔧 Useful Commands

### 🔐 AWS SSO Login (Recommended)

```bash
aws sso login --profile lz-admin

### 🪣 Create CloudTrail S3 Bucket
aws s3api create-bucket \
  --bucket aws-cloudguard-logs-eu-west-1 \
  --region eu-west-1 \
  --profile lz-admin \
  --create-bucket-configuration LocationConstraint=eu-west-1




###📦 Terraform Commands

cd environments/dev

# Initialize Terraform backend and modules
terraform init

# Check formatting
terraform fmt -check -recursive

# Create execution plan
terraform plan -out=tfplan.binary

# Apply changes (interactive)
terraform apply

# Apply saved plan
terraform apply tfplan.binary


###🪪 Debug AWS Identity in CI
Add this to GitHub Actions to verify identity:

- name: Debug caller identity
  run: aws sts get-caller-identity
