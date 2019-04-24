locals {
  s3_origin_id = "zilch.me"
}

resource "aws_route53_zone" "root" {
  name = "zilch.me"
}

resource "aws_s3_bucket" "root" {
  bucket = "zilch.me"
  acl    = "public-read"

  website {
    redirect_all_requests_to = "app.zilch.me"
  }
}

resource "aws_cloudfront_distribution" "root" {
  origin {
    domain_name = "${aws_s3_bucket.root.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
  }

  aliases = ["zilch.me"]

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # The cheapest priceclass
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.root.arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "root" {
  zone_id = "${aws_route53_zone.root.id}"
  name    = "zilch.me"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.root.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.root.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "root" {
  provider          = "aws.east"
  domain_name       = "zilch.me"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.root.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.root.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.root.id}"
  records = ["${aws_acm_certificate.root.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = "aws.east"
  certificate_arn         = "${aws_acm_certificate.root.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
