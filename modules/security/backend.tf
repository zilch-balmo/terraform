data "aws_network_interface" "nlb" {
  count = "${length(data.aws_subnet_ids.private.ids)}"

  filter = {
    name   = "description"
    values = ["ELB ${aws_lb.api.arn_suffix}"]
  }

  filter = {
    name   = "subnet-id"
    values = ["${element(data.aws_subnet_ids.private.ids, count.index)}"]
  }
}

resource "aws_security_group" "backend" {
  name   = "${var.name}.backend"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}.backend"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "backend_ingress_http" {
  security_group_id = "${aws_security_group.backend.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["0.0.0.0/0"]
}

/*
resource "aws_security_group_rule" "backend_ingress_http_nlb" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "TCP"
  cidr_blocks = ["${formatlist("%s/32",flatten(data.aws_network_interface.nlb.*.private_ips))}"]
  security_group_id = "${aws_security_group.nsg.id}"
}
*/

resource "aws_security_group_rule" "backend_egress_all" {
  security_group_id = "${aws_security_group.backend.id}"

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
