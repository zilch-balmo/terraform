data "aws_subnet_ids" "private" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}.private"
  }
}

data "archive_file" "database_admin" {
  type        = "zip"
  source_dir  = "${path.module}/source"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "database_admin" {
  filename         = "${substr(data.archive_file.database_admin.output_path, length(path.cwd) + 1, -1)}"
  function_name    = "database_admin"
  handler          = "handler.main"
  memory_size      = 128
  runtime          = "python3.7"
  role             = "${aws_iam_role.database_admin.arn}"
  source_code_hash = "${data.archive_file.database_admin.output_base64sha256}"
  timeout          = 5

  vpc_config {
    subnet_ids = [
      "${data.aws_subnet_ids.private.ids}",
    ]

    security_group_ids = [
      "${var.security_group_id}",
    ]
  }

  lifecycle {
    ignore_changes = [
      "last_modified",
    ]
  }
}

resource "aws_lambda_alias" "database_admin" {
  name             = "default"
  description      = "Use latest version as default"
  function_name    = "${aws_lambda_function.database_admin.function_name}"
  function_version = "$LATEST"
}
