resource "aws_route53_record" "backend" {
  provider = "aws.west"

  zone_id = "${var.zone_id}"
  name    = "backend.zilch.me"
  type    = "A"

  alias {
    // name    = "${data.aws_lb.alb.dns_name}"  // zone_id = "${data.aws_lb.alb.zone_id}"

    name                   = "${data.aws_lb.api.dns_name}"
    zone_id                = "${data.aws_lb.api.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "backend" {
  provider = "aws.west"

  domain_name       = "backend.zilch.me"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = "aws.west"

  name    = "${aws_acm_certificate.backend.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.backend.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.backend.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider = "aws.west"

  certificate_arn         = "${aws_acm_certificate.backend.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
