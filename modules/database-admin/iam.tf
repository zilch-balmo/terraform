data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "database_admin" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:secretsmanager:us-west-2:534764804984:secret:rds_backend_password-??????",
      "arn:aws:secretsmanager:us-west-2:534764804984:secret:rds_master_password-??????",
      "arn:aws:secretsmanager:us-west-2:534764804984:secret:secrets//backend-??????",
    ]
  }
}

resource "aws_iam_role" "database_admin" {
  name               = "${var.name}.database-admin"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_iam_policy" "database_admin" {
  name   = "${var.name}.database-admin"
  policy = "${data.aws_iam_policy_document.database_admin.json}"
}

resource "aws_iam_role_policy_attachment" "database_admin" {
  role       = "${aws_iam_role.database_admin.name}"
  policy_arn = "${aws_iam_policy.database_admin.arn}"
}

resource "aws_iam_role_policy_attachment" "database_admin_vpc" {
  role       = "${aws_iam_role.database_admin.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
