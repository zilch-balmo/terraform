resource "aws_secretsmanager_secret" "backend" {
  name = "secrets//backend"
}

resource "random_string" "backend_postgres_password" {
  length = 32
}

locals {
  secrets = {
    config = {
      postgres = {
        password = "${random_string.backend_postgres_password.result}"
      }
    }
  }
}

resource "aws_secretsmanager_secret_version" "backend" {
  secret_id     = "${aws_secretsmanager_secret.backend.id}"
  secret_string = "${jsonencode(local.secrets)}"
}
