resource "aws_iam_role" "backend" {
  name               = "backend"
  assume_role_policy = "${data.aws_iam_policy_document.ecs.json}"
}

resource "aws_iam_role_policy" "backend" {
  name   = "backend"
  policy = "${data.aws_iam_policy_document.backend.json}"
  role   = "${aws_iam_role.backend.id}"
}

data "aws_iam_policy_document" "ecs" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "backend" {
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
