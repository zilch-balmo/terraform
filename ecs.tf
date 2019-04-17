locals {
  cpu    = 256
  memory = 512
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/task-definitions/backend.json")}"
  vars = {
    cpu    = "${local.cpu}"
    memory = "${local.cpu}"
  }
}

resource "aws_ecs_cluster" "backend" {
  name = "backend"
}

resource "aws_ecs_task_definition" "backend" {
  container_definitions    = "${data.template_file.container_definitions.rendered}"
  cpu                      = "${local.cpu}"
  family                   = "backend"
  memory                   = "${local.memory}"
  network_mode             = "awsvpc"
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
    security_groups = ["${aws_security_group.ecs.id}"]
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
