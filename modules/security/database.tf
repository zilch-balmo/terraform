resource "aws_security_group" "database" {
  provider = aws.west

  name   = "${var.name}.database"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}.database"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "database_ingress_postgres" {
  provider = aws.west

  security_group_id = aws_security_group.database.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 5432
  to_port   = 5432

  source_security_group_id = aws_security_group.backend.id
}

resource "aws_security_group_rule" "database_egress_all" {
  provider = aws.west

  security_group_id = aws_security_group.database.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

