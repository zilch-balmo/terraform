/* Backend service.
 */

data "aws_subnet_ids" "private" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}.private"
  }
}

# ECR

resource "aws_ecr_repository" "backend" {
  name = "backend"

  lifecycle {
    prevent_destroy = true
  }
}

# ECS

data "template_file" "container_definitions" {
  template = "${file("${path.module}/task-definitions/backend.json")}"

  vars = {
    cpu           = "${var.fargate_cpu}"
    database_host = "${var.database_host}"
    image         = "${aws_ecr_repository.backend.repository_url}:latest"
    memory        = "${var.fargate_memory}"
    log_group     = "${aws_cloudwatch_log_group.backend.name}"
  }
}

resource "aws_ecs_task_definition" "backend" {
  container_definitions    = "${data.template_file.container_definitions.rendered}"
  cpu                      = "${var.fargate_cpu}"
  execution_role_arn       = "${var.execution_role_arn}"
  family                   = "backend"
  memory                   = "${var.fargate_memory}"
  network_mode             = "awsvpc"
  task_role_arn            = "${aws_iam_role.backend.arn}"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "backend" {
  cluster         = "${var.cluster_id}"
  desired_count   = 0
  launch_type     = "FARGATE"
  name            = "backend"
  task_definition = "${aws_ecs_task_definition.backend.arn}"

  depends_on = [
    "aws_alb_listener.backend_http",
    "aws_alb_listener.backend_https",
  ]

  network_configuration {
    security_groups = [
      "${var.security_group_id}",
    ]

    subnets = [
      "${data.aws_subnet_ids.private.ids}",
    ]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.backend_http_80.arn}"
    container_name   = "backend"
    container_port   = 80
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      "desired_count",
      "task_definition",
    ]
  }
}
