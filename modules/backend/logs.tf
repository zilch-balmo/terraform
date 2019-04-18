resource "aws_cloudwatch_log_group" "backend" {
  name              = "/fargate/service/backend"
  retention_in_days = "14"

  tags {
    Name = "${var.name}.backend"
  }
}
