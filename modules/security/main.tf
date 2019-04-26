data "aws_subnet_ids" "private" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}.private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}.public"
  }
}

/*
resource "aws_lb" "alb" {
  name = "${var.name}"

  subnets = [
    "${data.aws_subnet_ids.public.ids}",
  ]

  security_groups = [
    "${aws_security_group.alb.id}",
  ]

  tags {
    Name = "${var.name}"
  }
}
*/

resource "aws_lb" "api" {
  name                             = "${var.name}api"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"

  internal = true

  subnets = [
    "${data.aws_subnet_ids.private.ids}",
  ]

  tags {
    Name = "${var.name}"
  }
}
