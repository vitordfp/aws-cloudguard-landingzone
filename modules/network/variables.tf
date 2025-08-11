########################################
# Global
########################################

variable "prefix" {
  description = "Name prefix used in resource names/tags (e.g., cloudguard-dev)."
  type        = string
  default     = "cloudguard"
}

variable "aws_region" {
  description = "AWS region for networking resources."
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

########################################
# Hub VPC
########################################

variable "hub_vpc_cidr" {
  description = "CIDR block for the Hub VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# Keys must be actual AZ names in your region (e.g., eu-west-1a/b/c).
variable "hub_private_subnet_cidrs" {
  description = "Map of AZ => CIDR for Hub private subnets."
  type        = map(string)
  default = {
    "eu-west-1a" = "10.0.1.0/24"
    "eu-west-1b" = "10.0.2.0/24"
    "eu-west-1c" = "10.0.3.0/24"
  }
}

# Optional public subnets in the Hub (often omitted for a secure hub).
variable "hub_public_subnet_cidrs" {
  description = "Map of AZ => CIDR for Hub public subnets (empty map to skip)."
  type        = map(string)
  default     = {}
}

variable "hub_create_internet_gateway" {
  description = "Create an Internet Gateway for the Hub VPC (requires public subnets)."
  type        = bool
  default     = false
}

# none = no NAT; single = one NAT in first public AZ; multi = one NAT per public AZ
variable "hub_nat_strategy" {
  description = "NAT strategy for Hub VPC: 'none', 'single', or 'multi' (requires IGW + public subnets)."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "single", "multi"], var.hub_nat_strategy)
    error_message = "hub_nat_strategy must be one of: none, single, multi."
  }
}

########################################
# Spoke VPCs
########################################

variable "spokes" {
  description = <<EOT
        List of spoke VPC definitions. Each object:
    {
        name                    = "spoke1",
        vpc_cidr                = "10.10.0.0/16",
        private_subnet_cidrs    = { "eu-west-1a" = "10.10.1.0/24", "eu-west-1b" = "10.10.2.0/24" },
        public_subnet_cidrs     = {},           # optional; empty map to skip
        create_internet_gateway = false,        # set true if you define public subnets/egress
        nat_strategy            = "none"        # 'none' | 'single' | 'multi' (requires IGW + public)
    }
    EOT
  type = list(object({
    name                    = string
    vpc_cidr                = string
    private_subnet_cidrs    = map(string)
    public_subnet_cidrs     = map(string)
    create_internet_gateway = bool
    nat_strategy            = string
  }))
  default = [
    {
      name     = "spoke1"
      vpc_cidr = "10.10.0.0/16"
      private_subnet_cidrs = {
        "eu-west-1a" = "10.10.1.0/24"
        "eu-west-1b" = "10.10.2.0/24"
        "eu-west-1c" = "10.10.3.0/24"
      }
      public_subnet_cidrs     = {}
      create_internet_gateway = false
      nat_strategy            = "none"
    }
  ]
}

########################################
# Transit Gateway
########################################

variable "create_transit_gateway" {
  description = "Create a new Transit Gateway and attach hub + spokes."
  type        = bool
  default     = true
}

variable "tgw_auto_accept_shared_attachments" {
  description = "TGW auto accept shared attachments (enable/disable)."
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.tgw_auto_accept_shared_attachments)
    error_message = "tgw_auto_accept_shared_attachments must be 'enable' or 'disable'."
  }
}

variable "tgw_default_route_table_association" {
  description = "Associate attachments with TGW default route table (enable/disable)."
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.tgw_default_route_table_association)
    error_message = "tgw_default_route_table_association must be 'enable' or 'disable'."
  }
}

variable "tgw_default_route_table_propagation" {
  description = "Propagate routes to TGW default route table (enable/disable)."
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.tgw_default_route_table_propagation)
    error_message = "tgw_default_route_table_propagation must be 'enable' or 'disable'."
  }
}

########################################
# VPC Flow Logs (optional)
########################################

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs on hub and spokes."
  type        = bool
  default     = true
}

# 's3' to ship to S3 (bucket must exist), or 'cloudwatch' to a log group.
variable "flow_logs_destination_type" {
  description = "Destination for VPC Flow Logs: 's3' or 'cloudwatch'."
  type        = string
  default     = "s3"
  validation {
    condition     = contains(["s3", "cloudwatch"], var.flow_logs_destination_type)
    error_message = "flow_logs_destination_type must be 's3' or 'cloudwatch'."
  }
}

# If destination is S3, provide an existing bucket name. (Module won’t create it by default.)
variable "flow_logs_s3_bucket_name" {
  description = "S3 bucket name for VPC Flow Logs (required if destination_type = 's3')."
  type        = string
  default     = ""
}

# If destination is CloudWatch, the module will create the log group.
variable "flow_logs_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs (used if destination_type = 'cloudwatch')."
  type        = string
  default     = "/vpc/flowlogs"
}

variable "flow_logs_retention_days" {
  description = "Retention in days for CloudWatch VPC Flow Logs."
  type        = number
  default     = 90
}

variable "flow_logs_kms_key_id" {
  description = "KMS key ARN/ID for encrypting CloudWatch VPC Flow Logs (only if destination_type = 'cloudwatch')."
  type        = string
  default     = ""
}
