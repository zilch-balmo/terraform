locals {
  # We can scale up to four az. We must have at least two.
  min_az_count = 2
  max_az_count = 4
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_block}"

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_subnet" "private" {
  count             = "${local.min_az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.name}.private"
  }
}

resource "aws_subnet" "public" {
  count                   = "${local.min_az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, local.max_az_count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}.public"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.public.id}"
}

resource "aws_eip" "nat" {
  count = "${local.min_az_count}"
  vpc   = true

  depends_on = [
    "aws_internet_gateway.public",
  ]
}

resource "aws_nat_gateway" "nat" {
  count         = "${local.min_az_count}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table" "private" {
  count  = "${local.min_az_count}"
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.nat.*.id, count.index)}"
  }

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${local.min_az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
