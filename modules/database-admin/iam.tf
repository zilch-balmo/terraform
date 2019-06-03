data "aws_iam_policy_document" "assume_role_policy" {
  provider = "aws.west"

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
  provider = "aws.west"

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
      "arn:aws:secretsmanager:us-west-2:534764804984:secret:rds_*_password-??????",
    ]
  }
}

resource "aws_iam_role" "database_admin" {
  provider = "aws.west"

  name               = "${var.name}.database-admin"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

resource "aws_iam_policy" "database_admin" {
  provider = "aws.west"

  name   = "${var.name}.database-admin"
  policy = "${data.aws_iam_policy_document.database_admin.json}"
}

resource "aws_iam_role_policy_attachment" "database_admin" {
  provider = "aws.west"

  role       = "${aws_iam_role.database_admin.name}"
  policy_arn = "${aws_iam_policy.database_admin.arn}"
}

resource "aws_iam_role_policy_attachment" "database_admin_vpc" {
  provider = "aws.west"

  role       = "${aws_iam_role.database_admin.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
