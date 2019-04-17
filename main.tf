provider "aws" {
  profile             = "zilch"
  region              = "us-west-2"
  allowed_account_ids = ["534764804984"]
}

terraform {
  backend "s3" {
    bucket  = "terraform.zilch.me"
    key     = "terraform"
    profile = "zilch"
    region  = "us-west-2"
  }
}
