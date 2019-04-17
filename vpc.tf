locals {
  # we need at least two availability zones; we can scale up to four
  az_count     = 2
  max_az_count = 4
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "zilch"
  }
}

resource "aws_subnet" "private" {
  count             = "${local.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"

  tags = {
    Name = "zilch-private"
  }
}

resource "aws_subnet" "public" {
  count                   = "${local.az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 8, local.max_az_count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true

  tags = {
    Name = "zilch-public"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.public.id}"
}

resource "aws_eip" "nat" {
  count = "${local.az_count}"
  vpc   = true

  depends_on = [
    "aws_internet_gateway.public",
  ]
}

resource "aws_nat_gateway" "nat" {
  count         = "${local.az_count}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
}

resource "aws_route_table" "private" {
  count  = "${local.az_count}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.nat.*.id, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${local.az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
