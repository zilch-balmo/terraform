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
      "iam:PassRole",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::app.zilch.me",
    ]
  }
}

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
