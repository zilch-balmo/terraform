/* Backend service.
 */

# ECR

resource "aws_ecr_repository" "backend" {
  name = "backend"
}


# Logs

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/fargate/service/backend"
  retention_in_days = "14"

  tags {
    Name = "backend"
  }
}


# IAM

resource "aws_iam_role" "backend" {
  name               = "backend"
  assume_role_policy = "${data.aws_iam_policy_document.ecs.json}"
}

resource "aws_iam_role_policy" "backend" {
  name   = "backend"
  policy = "${data.aws_iam_policy_document.backend.json}"
  role   = "${aws_iam_role.backend.id}"
}

data "aws_iam_policy_document" "backend" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = [
      "arn:aws:logs:*",
    ]
  }
}

# ALB

resource "aws_alb_target_group" "backend" {
  name        = "backend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"

  tags = {
    Name = "backend"
  }
}

resource "aws_alb_listener" "backend" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.backend.id}"
    type             = "forward"
  }
}


# Security

resource "aws_security_group" "backend" {
  name   = "backend"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    security_groups = [
      "${aws_security_group.alb.id}",
    ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend"
  }
}


# ECS

locals {
  cpu    = 256
  memory = 512
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/task-definitions/backend.json")}"

  vars = {
    cpu       = "${local.cpu}"
    memory    = "${local.memory}"
    log_group = "${aws_cloudwatch_log_group.backend.name}"
  }
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
