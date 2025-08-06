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