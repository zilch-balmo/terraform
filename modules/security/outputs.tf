/*
output "alb_security_group_id" {
  value = "${aws_security_group.alb.id}"
}
*/

output "backend_security_group_id" {
  value = "${aws_security_group.backend.id}"
}

output "database_security_group_id" {
  value = "${aws_security_group.database.id}"
}

output "nlb_arn" {
  value = "${aws_lb.api.arn}"
}
