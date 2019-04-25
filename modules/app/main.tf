locals {
  s3_origin_id = "app.zilch.me"
}

resource "aws_s3_bucket" "app" {
  bucket = "app.zilch.me"
  acl    = "private"
}

data "aws_iam_policy_document" "app" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.app.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.app.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.app.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.app.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:*"]
    resources = [
      "${aws_s3_bucket.app.arn}",
      "${aws_s3_bucket.app.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${var.ci_user_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "app" {
  bucket = "${aws_s3_bucket.app.id}"
  policy = "${data.aws_iam_policy_document.app.json}"
}

resource "aws_cloudfront_origin_access_identity" "app" {}

resource "aws_cloudfront_distribution" "app" {
  origin {
    domain_name = "${aws_s3_bucket.app.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.app.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [
    "app.zilch.me",
  ]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags {
    Name = "${var.name}"
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.app.arn}"
    ssl_support_method  = "sni-only"
  }
}
