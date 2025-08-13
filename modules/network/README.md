# Network Module – CloudGuard Landing Zone

## Overview
The **Network** module provisions the core networking components for the CloudGuard Landing Zone using a **hub-and-spoke architecture**.  
It is designed to support multiple AWS environments with consistent tagging, security, and scalability.

Key features include:
- **Hub VPC** with optional public/private subnets, IGW, and NAT strategies.
- Configurable **spoke VPCs** with their own subnets, NAT, and IGW options.
- Optional **Transit Gateway** for centralized inter-VPC routing.
- **VPC Flow Logs** to S3 or CloudWatch, with optional KMS encryption.
- Fully parameterized for flexibility across environments.

---

## Features
- Centralized **Hub VPC** for shared services.
- Multiple **Spoke VPCs** for workloads, isolated by design.
- Flexible NAT deployment: `none`, `single`, or `multi`.
- Transit Gateway integration for multi-VPC routing.
- Support for **multi-AZ subnet deployment**.
- Centralized flow logging for security and compliance.
- Automatic tagging for cost allocation and governance.

---

## Requirements
- **Terraform** >= 1.3
- AWS CLI configured with credentials for a user/role with permissions to:
  - Create VPCs, subnets, route tables, IGWs, NAT gateways
  - Create Transit Gateways and VPC attachments
  - Create CloudWatch log groups and IAM roles
  - Create and manage S3 buckets for VPC Flow Logs (if using S3 destination)
- Basic knowledge of AWS networking concepts

---

## Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `prefix` | Name prefix for all resources. | `string` | n/a | yes |
| `hub_vpc_cidr` | CIDR block for the Hub VPC. | `string` | n/a | yes |
| `hub_private_subnet_cidrs` | Map of AZ => CIDR for Hub private subnets. | `map(string)` | `{}` | yes |
| `hub_public_subnet_cidrs` | Map of AZ => CIDR for Hub public subnets. | `map(string)` | `{}` | no |
| `hub_create_internet_gateway` | Whether to create an IGW for the Hub. | `bool` | `true` | no |
| `hub_nat_strategy` | NAT strategy: `none`, `single`, or `multi`. | `string` | `"none"` | no |
| `spokes` | List of spoke configurations (see Example Usage). | `list(object)` | `[]` | no |
| `create_transit_gateway` | Whether to create a Transit Gateway. | `bool` | `false` | no |
| `tgw_auto_accept_shared_attachments` | TGW auto-accept attachments setting. | `string` | `"disable"` | no |
| `enable_vpc_flow_logs` | Enable VPC Flow Logs. | `bool` | `false` | no |
| `flow_logs_destination_type` | Destination type for flow logs: `s3` or `cloudwatch`. | `string` | `"s3"` | no |
| `flow_logs_s3_bucket_name` | S3 bucket name for flow logs (if S3 destination). | `string` | `""` | conditional |
| `flow_logs_log_group_name` | CloudWatch log group name (if CloudWatch destination). | `string` | `""` | conditional |
| `flow_logs_retention_days` | Retention period in days for CloudWatch logs. | `number` | `90` | no |
| `flow_logs_kms_key_id` | ARN of KMS key for CloudWatch logs. | `string` | `""` | no |
| `tags` | Common tags applied to all resources. | `map(string)` | `{}` | no |

---

## Outputs

| Output | Description |
|--------|-------------|
| `hub_vpc_id` | The ID of the Hub VPC. |
| `spoke_vpc_ids` | Map of spoke names to their VPC IDs. |
| `tgw_id` | Transit Gateway ID (if created). |
| `hub_subnet_ids` | Map of subnet type to list of subnet IDs for the Hub. |
| `spoke_subnet_ids` | Map of spoke names to their subnet IDs. |
| `flow_logs_destination` | ARN of the flow logs destination. |

---

## Example Usage

```hcl
module "network" {
  source = "./modules/network"

  prefix = "lz"

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
  tgw_auto_accept_shared_attachments = "enable"

  enable_vpc_flow_logs        = true
  flow_logs_destination_type  = "s3"
  flow_logs_s3_bucket_name    = "my-flowlogs-bucket"

  tags = {
    Project     = "cloudguard-landingzone"
    Environment = "dev"
  }
}


Knowledge Check – General Module Questions
These questions apply to the entire module and help verify deep understanding.

How does the module decide whether to deploy NAT Gateways in single or multi-AZ mode?

What happens if you enable hub_nat_strategy but do not create any public subnets in the Hub?

Explain the benefits and drawbacks of enabling a Transit Gateway in this architecture.

Why might you choose CloudWatch over S3 for VPC Flow Logs?

How does the module ensure consistent tagging across all Hub and Spoke resources?

What changes would you make if you needed private subnets in the Hub to have internet access without public subnets?

How are spoke VPC configurations passed to the module, and how does Terraform handle them internally?

What AWS permissions are required for creating VPC Flow Logs with KMS encryption?

If you want to replicate this module for multiple environments (dev, staging, prod), how should you manage variables and prefixes?

In what scenarios would you set hub_create_internet_gateway to false, and what resources would be affected?