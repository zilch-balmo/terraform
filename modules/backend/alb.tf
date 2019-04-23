resource "aws_alb_target_group" "backend_http_80" {
  name        = "backendhttp80"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    interval            = 5
    matcher             = "200"
    path                = "/api/health"
    timeout             = 2
    unhealthy_threshold = 2
  }

  tags {
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
    type = "authenticate-cognito"

    authenticate_cognito {
      user_pool_arn       = "${var.user_pool_arn}"
      user_pool_client_id = "${var.user_pool_client_id}"
      user_pool_domain    = "${var.user_pool_domain}"
    }
  }

  default_action {
    target_group_arn = "${aws_alb_target_group.backend_http_80.id}"
    type             = "forward"
  }
}
