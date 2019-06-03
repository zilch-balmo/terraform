resource "aws_acm_certificate" "auth" {
  # AWS Cognito requires the certificate to be in us-east-1
  provider = aws.east

  domain_name       = "auth.zilch.me"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.west

  name    = aws_acm_certificate.auth.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.auth.domain_validation_options[0].resource_record_type
  zone_id = var.zone_id
  records = [aws_acm_certificate.auth.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  # AWS Cognito requires the certificate to be in us-east-1
  provider = aws.east

  certificate_arn         = aws_acm_certificate.auth.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

resource "aws_route53_record" "cognito_auth" {
  provider = aws.west

  zone_id = var.zone_id
  name    = "auth.zilch.me"
  type    = "A"

  alias {
    name = aws_cognito_user_pool_domain.main.cloudfront_distribution_arn

    // The following zone id is CloudFront.
    // See https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-aliastarget.html
    zone_id = "Z2FDTNDATAQYW2"

    evaluate_target_health = false
  }
}

