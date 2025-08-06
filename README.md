# 🛡️ AWS CloudGuard Landing Zone

This repository provides a modular and secure AWS Landing Zone setup using Terraform. It follows AWS best practices for managing multi-account environments with infrastructure-as-code and GitHub Actions for CI/CD.

---

## 📁 Project Structure
├── .github/workflows # CI/CD workflows (plan, apply, security scans)
├── environments/ # Environment-specific Terraform configurations (e.g., dev, prod)
├── modules/ # Reusable Terraform modules (org, network, security, visionguard-s3)
├── scripts/ # Utility scripts (bootstrap, cleanup)
├── docs/ # Documentation (architecture, usage)


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
