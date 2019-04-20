/* Manage DNS.
 */

resource "aws_route53_zone" "root" {
  name = "zilch.me"
}

# XXX we must have an A record in order to use Cognito custom domains
resource "aws_route53_record" "root" {
  zone_id = "${aws_route53_zone.root.id}"
  name    = "zilch.me"
  type    = "A"
  ttl     = "300"
  records = ["74.208.236.70"]
}
