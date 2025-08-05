terraform {
  backend "s3" {
    bucket         = "cloudguard-tfstate-770763203431"
    key            = "dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "cloudguard-tflock"
    encrypt        = true
  }
}