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
  value = "${aws_security_group.ingress.id}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "execution_role_arn" {
  value = "${aws_iam_role.ecs.arn}"
}
