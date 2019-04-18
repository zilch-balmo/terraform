/* Account */

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 16
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = false
  allow_users_to_change_password = true
}

/* Admin */

resource "aws_iam_group" "administrators" {
  name = "administrators"
}

resource "aws_iam_group_policy_attachment" "administrators" {
  group      = "${aws_iam_group.administrators.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

/* CI */

resource "aws_iam_group" "ci" {
  name = "ci"
}

resource "aws_iam_policy" "ci" {
  name   = "ci"
  policy = "${data.aws_iam_policy_document.ci.json}"
}

resource "aws_iam_group_policy_attachment" "ci" {
  group      = "${aws_iam_group.ci.name}"
  policy_arn = "${aws_iam_policy.ci.arn}"
}

resource "aws_iam_user" "ci" {
  name = "ci"
}

resource "aws_iam_user_group_membership" "ci" {
  user = "${aws_iam_user.ci.name}"

  groups = [
    "${aws_iam_group.ci.name}",
  ]
}

data "aws_iam_policy_document" "ci" {
  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      "*",
    ]
  }
}

/* ECS */

resource "aws_iam_role" "ecs" {
  name               = "ecs"
  assume_role_policy = "${data.aws_iam_policy_document.ecs.json}"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = "${aws_iam_role.ecs.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
