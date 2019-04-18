/* RDS persistence.
 */

data "aws_secretsmanager_secret" "rds_master_password" {
  name = "rds_master_password"
}

data "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id = "${data.aws_secretsmanager_secret.rds_master_password.id}"
}

resource "aws_security_group" "postgres" {
  name   = "postgres"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432

    security_groups = [
      "${aws_security_group.backend.id}",
    ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "postgres"
  }
}

resource "aws_db_subnet_group" "postgres" {
  name = "postgres"

  subnet_ids = [
    "${aws_subnet.private.*.id}",
  ]

  tags = {
    Name = "postgres"
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage         = 20
  db_subnet_group_name      = "${aws_db_subnet_group.postgres.name}"
  deletion_protection       = true
  engine                    = "postgres"
  engine_version            = "11.1"
  final_snapshot_identifier = "zilch-final"
  identifier                = "zilch"
  instance_class            = "db.t3.micro"

  # multi AZ doubles price; enable when we need it
  multi_az               = false
  password               = "${data.aws_secretsmanager_secret_version.rds_master_password.secret_string}"
  username               = "postgres"
  vpc_security_group_ids = ["${aws_security_group.postgres.id}"]

  tags = {
    Name = "postgres"
  }
}
