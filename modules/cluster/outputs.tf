output "security_group_id" {
  value = "${aws_security_group.ingress.id}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "execution_role_arn" {
  value = "${aws_iam_role.ecs.arn}"
}
