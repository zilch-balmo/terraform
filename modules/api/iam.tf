resource "aws_iam_role" "api" {
  provider = aws.west

  name               = "api"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "api" {
  provider = aws.west

  name   = "api"
  policy = data.aws_iam_policy_document.api.json
  role   = aws_iam_role.api.id
}

data "aws_iam_policy_document" "assume_role" {
  provider = aws.west

  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "apigateway.amazonaws.com",
      ]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "api" {
  provider = aws.west

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

