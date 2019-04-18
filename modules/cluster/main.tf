resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}-${var.tier}"
}

resource "aws_security_group" "ingress" {
  name   = "${var.name}.${var.tier}.ingress"
  vpc_id = "${var.vpc_id}"

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
    Name = "${var.name}.${var.tier}.ingress"
  }

  lifecycle {
    create_before_destroy = true
  }
}
