/* AWS NatGatway costs about $1/day per instance. We should be able to do better using a t2.micro instance.
 *
 * See: https://github.com/terraform-community-modules/tf_aws_nat/blob/master/main.tf
 */
resource "aws_security_group" "nat" {
  provider = "aws.west"

  name        = "nat"
  description = "Allow nat traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "nat" {
  provider = "aws.west"

  statement {
    effect = "Allow"

    actions = [
      "ec2:ReplaceRoute",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DescribeRouteTables",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceAttribute",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "assume_role" {
  provider = "aws.west"

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

data "aws_region" "current" {
  provider = "aws.west"
}

resource "aws_iam_instance_profile" "nat" {
  provider = "aws.west"

  name = "${var.name}.nat"
  role = "${aws_iam_role.nat.name}"
}

resource "aws_iam_role" "nat" {
  provider = "aws.west"

  name               = "${var.name}.nat"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "nat" {
  provider = "aws.west"

  name   = "${var.name}.nat"
  role   = "${aws_iam_role.nat.id}"
  policy = "${data.aws_iam_policy_document.nat.json}"
}

data "aws_ami" "ami" {
  provider = "aws.west"

  most_recent = true

  filter {
    name   = "name"
    values = ["${var.ami_name_pattern}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.ami_publisher}"]
}

data "template_file" "user_data" {
  count = "${local.min_az_count}"

  template = "${file("${path.module}/nat.conf.tmpl")}"

  vars = {
    name              = "${var.name}"
    mysubnet          = "${element(aws_subnet.private.*.id, count.index)}"
    vpc_cidr          = "${aws_vpc.vpc.cidr_block}"
    region            = "${data.aws_region.current.name}"
    awsnycast_deb_url = "https://github.com/bobtfish/AWSnycast/releases/download/v0.1.5/awsnycast_0.1.5-425_amd64.deb"
    identifier        = "rt-private"
  }
}

resource "aws_instance" "nat" {
  provider = "aws.west"

  count = "${local.min_az_count}"

  ami                    = "${data.aws_ami.ami.id}"
  instance_type          = "t2.nano"
  source_dest_check      = false
  iam_instance_profile   = "${aws_iam_instance_profile.nat.id}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  user_data              = "${element(data.template_file.user_data.*.rendered, count.index)}"

  tags = {
    Name = "${var.name}.nat"
  }
}

/*
resource "aws_eip" "nat" {
  provider = "aws.west"

  count = "${local.min_az_count}"
  vpc   = true

  depends_on = [
    "aws_internet_gateway.public",
  ]
}

resource "aws_nat_gateway" "nat" {
  provider = "aws.west"

  count         = "${local.min_az_count}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"

  tags = {
    Name = "${var.name}"
  }
}
*/

resource "aws_route_table" "private" {
  provider = "aws.west"

  count  = "${local.min_az_count}"
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${element(aws_instance.nat.*.id, count.index)}"

    /* nat_gateway_id = "${element(aws_nat_gateway.nat.*.id, count.index)}" */
  }

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table_association" "private" {
  provider = "aws.west"

  count          = "${local.min_az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
