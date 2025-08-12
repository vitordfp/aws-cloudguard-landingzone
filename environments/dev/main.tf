terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  #profile = "lz-admin"
}

module "org" {
  source               = "../../modules/org"
  organizational_units = ["SecurityTeam", "DevOpsTeam"]
  scp_policies = {
    DenyGlobalServices = "p-57oic78t"
  }
}

module "network" {
  source = "../../modules/network"

  # General naming
  prefix = "dev"

  # Hub VPC
  hub_vpc_cidr = "10.0.0.0/16"
  hub_private_subnet_cidrs = {
    "eu-west-1a" = "10.0.1.0/24"
    "eu-west-1b" = "10.0.2.0/24"
  }
  hub_public_subnet_cidrs = {
    "eu-west-1a" = "10.0.101.0/24"
    "eu-west-1b" = "10.0.102.0/24"
  }
  hub_nat_strategy            = "single"
  hub_create_internet_gateway = true

  # Transit Gateway
  create_transit_gateway              = true
  tgw_auto_accept_shared_attachments  = "enable"
  tgw_default_route_table_association = "enable"
  tgw_default_route_table_propagation = "enable"

  # Example spoke
  spokes = [
    {
      name                    = "spoke1"
      vpc_cidr                = "10.1.0.0/16"
      private_subnet_cidrs    = { "eu-west-1a" = "10.1.1.0/24" }
      public_subnet_cidrs     = { "eu-west-1a" = "10.1.101.0/24" }
      create_internet_gateway = true
      nat_strategy            = "single"
    }
  ]

  # Tags applied to all resources
  tags = {
    Project     = "cloudguard-landingzone"
    Environment = "dev"
  }

  # Enable VPC Flow Logs (to CloudWatch)
  enable_vpc_flow_logs       = true
  flow_logs_destination_type = "cloudwatch"
  flow_logs_log_group_name   = "/aws/vpc/flowlogs/hub"
  flow_logs_retention_days   = 90
  # flow_logs_kms_key_id     = "arn:aws:kms:eu-west-1:123456789012:key/your-key-id" # optional
}
