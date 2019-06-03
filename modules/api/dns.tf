resource "aws_route53_record" "api" {
  provider = aws.west

  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api.cloudfront_zone_id
  }
}

resource "aws_acm_certificate" "api" {
  provider = aws.east

  domain_name       = "api.zilch.me"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.west

  name    = aws_acm_certificate.api.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.api.domain_validation_options[0].resource_record_type
  zone_id = var.zone_id
  records = [aws_acm_certificate.api.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider = aws.east

  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

