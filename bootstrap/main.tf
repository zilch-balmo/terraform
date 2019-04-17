provider "aws" {
  profile             = "zilch"
  region              = "us-west-2"
  allowed_account_ids = ["534764804984"]
}

/* Bucket to store terraform state.
 */
resource "aws_s3_bucket" "terraform" {
  bucket = "terraform.zilch.me"
  acl    = "private"

  versioning {
    enabled = true
  }
}

/* RDS master password.
 */
resource "aws_secretsmanager_secret" "rds_master_password" {
  name = "rds_master_password"
}

resource "random_string" "rds_master_password" {
  length = 32
}

resource "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id     = "${aws_secretsmanager_secret.rds_master_password.id}"
  secret_string = "${random_string.rds_master_password.result}"
}
