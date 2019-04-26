locals {
  # We can scale up to four az. We must have at least two.
  min_az_count = 2
  max_az_count = 4
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_block}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_subnet" "private" {
  count             = "${local.min_az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.name}.private"
  }
}

resource "aws_subnet" "public" {
  count                   = "${local.min_az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, local.max_az_count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name}.public"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.public.id}"
}

resource "aws_instance" "test" {
  ami                    = "${data.aws_ami.ami.id}"
  key_name               = "jesse"
  instance_type          = "t2.nano"
  source_dest_check      = false
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]

  tags {
    Name = "${var.name}"
  }
}
