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
  region  = "eu-west-1"
  #profile = "lz-admin"
}

module "org" {
  source               = "../../modules/org"
  organizational_units = ["SecurityTeam", "DevOpsTeam"]
  scp_policies = {
    DenyGlobalServices = "arn:aws:organizations::770763203431:policy/o-03tvkc8u4y/service_control_policy/p-57oic78t"
  }
}