# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"

  tags = "${
    map(
     "Name", "eks-${var.project_name}-${var.env}",
     "kubernetes.io/cluster/${var.project_name}-${var.env}", "shared",
    )
  }"
}

resource "aws_subnet" "subnet" {
  count = length(var.subnets)

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.subnets[count.index]}"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags = "${
    map(
     "Name", "eks-${var.project_name}-${var.env}-${count.index}",
     "kubernetes.io/cluster/${var.project_name}-${var.env}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${
    map(
     "Name", "eks-${var.project_name}-${var.env}"
    )
  }"
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags = "${
    map(
     "Name", "eks-${var.project_name}-${var.env}"
    )
  }"
}

resource "aws_route_table_association" "rta" {
  count = length(var.subnets)

  subnet_id      = "${aws_subnet.subnet[count.index].id}"
  route_table_id = "${aws_route_table.rt.id}"
}
