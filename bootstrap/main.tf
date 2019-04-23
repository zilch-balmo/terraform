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

resource "null_resource" "rds_master_password" {
  depends_on = [
    "aws_secretsmanager_secret.rds_master_password",
  ]

  provisioner "local-exec" {
    command = "aws --profile zilch secretsmanager put-secret-value --secret-id rds_master_password --secret-string $(openssl rand -base64 32)"
  }
}
