output "alb_id" {
  value = "${aws_alb.alb.id}"
}

output "alb_dns_name" {
  value = "${aws_alb.alb.dns_name}"
}

output "alb_zone_id" {
  value = "${aws_alb.alb.zone_id}"
}

output "security_group_id" {
  value = "${aws_security_group.alb.id}"
}

output "zone_id" {
  value = "${aws_route53_zone.root.zone_id}"
}
