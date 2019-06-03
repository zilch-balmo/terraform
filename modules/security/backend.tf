data "aws_network_interface" "nlb" {
  provider = aws.west

  count = length(data.aws_subnet_ids.private.ids)

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.api.arn_suffix}"]
  }

  filter {
    name = "subnet-id"
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    values = [element(tolist(data.aws_subnet_ids.private.ids), count.index)]
  }
}

resource "aws_security_group" "backend" {
  provider = aws.west

  name   = "${var.name}.backend"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}.backend"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "backend_ingress_http" {
  provider = aws.west

  security_group_id = aws_security_group.backend.id

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["0.0.0.0/0"]
}

/*
resource "aws_security_group_rule" "backend_ingress_http_nlb" {
  provider = "aws.west"

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "TCP"
  cidr_blocks = ["${formatlist("%s/32",flatten(data.aws_network_interface.nlb.*.private_ips))}"]
  security_group_id = "${aws_security_group.nsg.id}"
}
*/

resource "aws_security_group_rule" "backend_egress_all" {
  provider = aws.west

  security_group_id = aws_security_group.backend.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

