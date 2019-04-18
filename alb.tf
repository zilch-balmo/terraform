/* Create application load balancer.
 */

resource "aws_security_group" "alb" {
  name   = "alb"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb"
  }
}

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
