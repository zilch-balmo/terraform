resource "aws_alb_target_group" "backend" {
  name        = "backend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  tags = {
    Name = "backend"
  }
}

resource "aws_alb_listener" "backend" {
  load_balancer_arn = "${var.alb_id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.backend.id}"
    type             = "forward"
  }
}
