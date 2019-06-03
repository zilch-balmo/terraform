resource "aws_secretsmanager_secret" "rds_backend_password" {
  provider = "aws.west"

  name = "rds_backend_password"
}

resource "null_resource" "rds_backend_password" {
  depends_on = [
    "aws_secretsmanager_secret.rds_backend_password",
  ]

  provisioner "local-exec" {
    command = "aws --profile zilch secretsmanager put-secret-value --secret-id rds_backend_password --secret-string $(openssl rand -base64 32)"
  }
}
