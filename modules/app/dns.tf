resource "aws_route53_record" "app" {
  zone_id = "${var.zone_id}"
  name    = "app.zilch.me"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.app.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.app.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "app" {
  provider          = "aws.east"
  domain_name       = "app.zilch.me"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.app.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.app.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.app.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = "aws.east"
  certificate_arn         = "${aws_acm_certificate.app.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
