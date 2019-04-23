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

resource "aws_iam_role" "ecs" {
  name               = "${var.name}.${var.tier}.ecs"
  assume_role_policy = "${data.aws_iam_policy_document.ecs.json}"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = "${aws_iam_role.ecs.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "secrets" {
  name = "${var.name}.secrets.ecs"
  policy = "${data.aws_iam_policy_document.secrets.json}"
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = "${aws_iam_role.ecs.name}"
  policy_arn = "${aws_iam_policy.secrets.arn}"
}

data "aws_iam_policy_document" "secrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:Describe*",
      "secretsmanager:Get*",
      "secretsmanager:List*",
    ]

    resources = [
      "*"
    ]
  }
}
