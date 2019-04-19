resource "aws_alb_target_group" "backend" {
  name        = "backend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  tags = {
    Name = "${var.name}.backend"
  }
}

resource "aws_alb_listener" "backend_http" {
  load_balancer_arn = "${var.alb_id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "backend_https" {
  load_balancer_arn = "${var.alb_id}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_acm_certificate.backend.arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.backend.id}"
    type             = "forward"
  }
}
