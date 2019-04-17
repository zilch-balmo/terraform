provider "aws" {
  profile             = "zilch"
  region              = "us-west-2"
  allowed_account_ids = ["534764804984"]
}

resource "aws_s3_bucket" "terraform" {
  bucket = "terraform.zilch.me"
  acl    = "private"

  versioning {
    enabled = true
  }
}
