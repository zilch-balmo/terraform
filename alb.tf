/* Create application load balancer.
 */

resource "aws_alb" "main" {
  name = "alb"

  subnets = [
    "${aws_subnet.public.*.id}",
  ]

  security_groups = [
    "${aws_security_group.alb.id}",
  ]

  tags = {
    Name = "zilch"
  }
}

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
