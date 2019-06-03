data "aws_subnet_ids" "private" {
  provider = aws.west

  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}.private"
  }
}

data "aws_subnet_ids" "public" {
  provider = aws.west

  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}.public"
  }
}

/*
resource "aws_lb" "alb" {
  provider = "aws.west"

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
  provider = aws.west

  name                             = "${var.name}api"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"

  internal = true

  subnets = data.aws_subnet_ids.private.ids

  tags = {
    Name = var.name
  }
}

