# Account-level IAM setup.

resource "aws_iam_account_password_policy" "strict" {
  provider = "aws.west"

  minimum_password_length        = 16
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = false
  allow_users_to_change_password = true
}

resource "aws_iam_group" "administrators" {
  provider = "aws.west"

  name = "administrators"
}

resource "aws_iam_group_policy_attachment" "administrators" {
  provider = "aws.west"

  group      = aws_iam_group.administrators.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
