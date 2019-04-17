/* Define services.
 */

locals {
  cpu    = 256
  memory = 512
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/fargate/service/backend"
  retention_in_days = "14"

  tags {
    Name = "backend"
  }
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/task-definitions/backend.json")}"

  vars = {
    cpu       = "${local.cpu}"
    memory    = "${local.memory}"
    log_group = "${aws_cloudwatch_log_group.backend.name}"
  }
}

resource "aws_ecs_cluster" "backend" {
  name = "backend"
}

resource "aws_ecs_task_definition" "backend" {
  container_definitions    = "${data.template_file.container_definitions.rendered}"
  cpu                      = "${local.cpu}"
  execution_role_arn       = "${aws_iam_role.ecs.arn}"
  family                   = "backend"
  memory                   = "${local.memory}"
  network_mode             = "awsvpc"
  task_role_arn            = "${aws_iam_role.backend.arn}"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "backend" {
  cluster         = "${aws_ecs_cluster.backend.id}"
  desired_count   = 0
  launch_type     = "FARGATE"
  name            = "backend"
  task_definition = "${aws_ecs_task_definition.backend.arn}"

  depends_on = [
    "aws_alb_listener.backend",
  ]

  network_configuration {
    security_groups = ["${aws_security_group.backend.id}"]
    subnets         = ["${aws_subnet.private.*.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.backend.arn}"
    container_name   = "backend"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [
      "desired_count",
    ]
  }
}
