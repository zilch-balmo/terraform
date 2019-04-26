resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = "${aws_iam_role.api.arn}"
}

resource "aws_api_gateway_domain_name" "api" {
  certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
  domain_name     = "api.zilch.me"
}

resource "aws_api_gateway_vpc_link" "api" {
  name        = "${var.name}"
  target_arns = ["${var.nlb_arn}"]
}


resource "aws_api_gateway_rest_api" "api" {
  name = "${var.name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "api" {
  name          = "${var.name}.auth"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  provider_arns = ["${var.user_pool_arn}"]
  type          = "COGNITO_USER_POOLS"
}

resource "aws_api_gateway_resource" "api_proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "api_proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.api_proxy.id}"
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  // can use authorization_scopes here too
  authorizer_id = "${aws_api_gateway_authorizer.api.id}"

  request_parameters = {
    "method.request.path.proxy" = true
    "method.request.header.Authorization" = true
  }
}

// a method response doesn't seem necessary for a proxy?

resource "aws_api_gateway_integration" "api_proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.api_proxy.id}"
  http_method = "${aws_api_gateway_method.api_proxy.http_method}"

  type            = "HTTP_PROXY"
  connection_type = "VPC_LINK"
  connection_id   = "${aws_api_gateway_vpc_link.api.id}"
  integration_http_method = "ANY"
  timeout_milliseconds = 2000

  # XXX try backend.zilch.me; use variable from module.security
  uri = "http://zilchapi-d3bbbd4647139c84.elb.us-west-2.amazonaws.com/{proxy}"

  cache_key_parameters = [
    "method.request.path.proxy",
  ]

  request_parameters = {
    "integration.request.header.Authorization" = "method.request.header.Authorization"
    "integration.request.path.proxy"           = "method.request.path.proxy"
  }

}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "prod"

  depends_on = [
    "aws_api_gateway_integration.api_proxy",
  ]
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id      = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${aws_api_gateway_deployment.api.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.api.domain_name}"
}

resource "aws_api_gateway_stage" "api_prod" {
  stage_name    = "prod"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  deployment_id = "${aws_api_gateway_deployment.api.id}"
}

resource "aws_api_gateway_usage_plan" "api" {
  name = "${var.name}"

  # XXX test me
  api_stages {
    api_id = "${aws_api_gateway_rest_api.api.id}"
    stage  = "${aws_api_gateway_deployment.api.stage_name}"
  }

  quota_settings {
    limit  = 100
    offset = 0
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 10
    rate_limit  = 5
  }
}

resource "aws_api_gateway_method_settings" "api" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${aws_api_gateway_stage.api_prod.stage_name}"
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "ERROR"
  }
}
