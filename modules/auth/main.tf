resource "aws_cognito_user_pool" "pool" {
  provider = aws.west

  name = var.name

  admin_create_user_config {
    # require admins to create users for now
    allow_admin_create_user_only = true

    invite_message_template {
      email_message = <<EOF
We are now using Cognito for auth to https://backend.zilch.com

Your username is {username} and temporary password is {####}.
EOF


      email_subject = "[zilch]: Your temporary password"
      sms_message = "Your username is {username} and temporary password is {####}. "
    }
  }

  password_policy {
    minimum_length = 8
    require_lowercase = false
    require_numbers = false
    require_symbols = false
    require_uppercase = false
  }

  sms_authentication_message = "Your authentication code is {####}. "
  sms_verification_message = "Your verification code is {####}. "

  tags = {
    Name = var.name
  }
}

resource "aws_cognito_user_pool_client" "app" {
  provider = aws.west

  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_flows = [
    "code",
    "implicit",
  ]

  allowed_oauth_scopes = [
    "aws.cognito.signin.user.admin",
    "email",
    "openid",
    "phone",
    "profile",
  ]

  callback_urls = [
    "https://app.zilch.me",
  ]

  logout_urls = [
    "https://app.zilch.me",
  ]

  # NB: JavaScript application are not compatible with clients that use a secret
  generate_secret = false
  name = "${var.name}.app"
  supported_identity_providers = ["COGNITO"]
  user_pool_id = aws_cognito_user_pool.pool.id
}

/*
resource "aws_cognito_user_pool_client" "backend" {
  provider = "aws.west"

  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_flows = [
    "code",
    "implicit",
  ]

  allowed_oauth_scopes = [
    "aws.cognito.signin.user.admin",
    "email",
    "openid",
    "phone",
    "profile",
  ]

  callback_urls = [
    "https://backend.zilch.me/oauth2/idpresponse",
  ]

  logout_urls = []

  generate_secret              = true
  name                         = "${var.name}.backend"
  supported_identity_providers = ["COGNITO"]
  user_pool_id                 = "${aws_cognito_user_pool.pool.id}"
}
*/

resource "aws_cognito_user_pool_domain" "main" {
  provider = aws.west

  depends_on = [aws_acm_certificate_validation.cert]

  domain = "auth.zilch.me"
  certificate_arn = aws_acm_certificate.auth.arn
  user_pool_id = aws_cognito_user_pool.pool.id
}

