/* Create application load balancer.
 */

data "aws_subnet_ids" "public" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "${var.name}.public"
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.name}.${var.tier}.alb"
  vpc_id = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}.${var.tier}.alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb" "alb" {
  name = "${var.name}-${var.tier}"

  subnets = [
    "${data.aws_subnet_ids.public.ids}",
  ]

  security_groups = [
    "${aws_security_group.alb.id}",
  ]

  tags = {
    Name = "${var.name}.${var.tier}"
  }
}
