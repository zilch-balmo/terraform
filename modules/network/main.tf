locals {
  # We can scale up to four az. We must have at least two.
  min_az_count = 2
  max_az_count = 4
}

data "aws_availability_zones" "available" {
  provider = "aws.west"
}

resource "aws_vpc" "vpc" {
  provider = "aws.west"

  cidr_block = "${var.cidr_block}"

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_subnet" "private" {
  provider = "aws.west"

  count             = "${local.min_az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.name}.private"
  }
}

resource "aws_subnet" "public" {
  provider = "aws.west"

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
  provider = "aws.west"

  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route" "internet_access" {
  provider = "aws.west"

  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.public.id}"
}
