# Usage Guide – CloudGuard Landing Zone

This guide explains how to deploy the CloudGuard Landing Zone framework, configure its backend, customize parameters, and troubleshoot common issues.

---

## 1. Backend Configuration (`backend.tf`)

Terraform stores its state remotely using an S3 bucket and a DynamoDB table for state locking.  
Create a `backend.tf` file in each environment folder (`environments/dev`, `environments/prod`, etc.) with the following structure:

```hcl
terraform {
  backend "s3" {
    bucket         = "<your-s3-bucket-name>"
    key            = "<path-to-your-tfstate-file>"
    region         = "<aws-region>"
    dynamodb_table = "<your-dynamodb-table>"
    encrypt        = true
  }
}
```

**Parameters:**
- **`bucket`** – The name of the S3 bucket for storing the Terraform state.
- **`key`** – The path/key for the state file (e.g., `dev/terraform.tfstate`).
- **`region`** – AWS region where the S3 bucket and DynamoDB table are located.
- **`dynamodb_table`** – Name of the DynamoDB table used for state locking.
- **`encrypt`** – Always `true` for encryption at rest.

---

## 2. Module Parameters (Inputs)

The framework is fully parameterized. Below is a reference for the most important inputs, with defaults where applicable.

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `prefix` | Prefix for all resource names. | `string` | n/a | yes |
| `hub_vpc_cidr` | CIDR block for the Hub VPC. | `string` | n/a | yes |
| `hub_private_subnet_cidrs` | AZ => CIDR mapping for Hub private subnets. | `map(string)` | `{}` | yes |
| `hub_public_subnet_cidrs` | AZ => CIDR mapping for Hub public subnets. | `map(string)` | `{}` | no |
| `hub_create_internet_gateway` | Whether to create IGW for Hub. | `bool` | `true` | no |
| `hub_nat_strategy` | NAT strategy (`none`, `single`, `multi`). | `string` | `"none"` | no |
| `spokes` | List of spoke VPC configs. | `list(object)` | `[]` | no |
| `create_transit_gateway` | Create a Transit Gateway. | `bool` | `false` | no |
| `enable_vpc_flow_logs` | Enable VPC Flow Logs. | `bool` | `false` | no |
| `flow_logs_destination_type` | `s3` or `cloudwatch`. | `string` | `"s3"` | no |
| `flow_logs_s3_bucket_name` | S3 bucket name for flow logs. | `string` | `""` | conditional |
| `flow_logs_log_group_name` | CloudWatch log group name. | `string` | `""` | conditional |
| `flow_logs_retention_days` | Retention days for logs. | `number` | `90` | no |
| `tags` | Common tags for resources. | `map(string)` | `{}` | no |

For the full list, see the `variables.tf` in each module.

---

## 3. Example Environment Configuration

Example for `environments/dev/main.tf`:

```hcl
module "network" {
  source = "../../modules/network"

  prefix = "lz-dev"

  hub_vpc_cidr = "10.0.0.0/16"
  hub_private_subnet_cidrs = {
    "eu-west-1a" = "10.0.1.0/24"
    "eu-west-1b" = "10.0.2.0/24"
  }
  hub_public_subnet_cidrs = {
    "eu-west-1a" = "10.0.101.0/24"
    "eu-west-1b" = "10.0.102.0/24"
  }
  hub_create_internet_gateway = true
  hub_nat_strategy = "single"

  spokes = [
    {
      name                   = "spoke1"
      vpc_cidr               = "10.1.0.0/16"
      private_subnet_cidrs   = { "eu-west-1a" = "10.1.1.0/24" }
      public_subnet_cidrs    = { "eu-west-1a" = "10.1.101.0/24" }
      create_internet_gateway = true
      nat_strategy            = "single"
    }
  ]

  create_transit_gateway = true

  enable_vpc_flow_logs        = true
  flow_logs_destination_type  = "cloudwatch"
  flow_logs_log_group_name    = "/aws/vpc/flowlogs/hub"
  flow_logs_retention_days    = 90

  tags = {
    Project     = "cloudguard-landingzone"
    Environment = "dev"
  }
}
```

---

## 4. Deployment Commands

### Development Environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Production Environment

```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

---

## 5. Troubleshooting Tips

| Error | Possible Cause | Solution |
|-------|---------------|----------|
| `Invalid provider configuration` | AWS credentials missing. | Run `aws configure` or set environment variables for AWS. |
| `No valid credential sources found` | No credentials available for Terraform. | Ensure your AWS CLI is configured and that OIDC roles are correctly set if using GitHub Actions. |
| `Unsupported argument 'log_group_name'` | Terraform AWS provider version mismatch. | Update the AWS provider to the correct version that supports the argument. |
| State locking errors | DynamoDB table missing or not accessible. | Verify the DynamoDB table exists and your IAM role has `dynamodb:*` permissions. |

---

## 6. Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
- AWS Networking Documentation:
  - [VPC Overview](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
  - [Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
  - [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
