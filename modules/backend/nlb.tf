data "aws_lb" "api" {
  name = "${var.name}api"
}

resource "aws_lb_target_group" "api" {
  name                 = "${var.name}api"
  port                 = 80
  protocol             = "TCP"
  vpc_id               = "${var.vpc_id}"
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    healthy_threshold   = 2
    interval            = 10
    protocol            = "TCP"
    unhealthy_threshold = 2
  }

  tags {
    Name = "${var.name}"
  }
}

resource "aws_lb_listener" "api_tcp" {
  load_balancer_arn = "${data.aws_lb.api.id}"
  port              = 80
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.api.id}"
    type             = "forward"
  }
}
