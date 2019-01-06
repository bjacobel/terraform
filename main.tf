provider "aws" {
  region  = "${var.region}"
  version = "~> 1.50"
}

// The lines below set up common infra; everything you need to do anything interesting in AWS.
// The actual interesting stuff is in the modules (e.g., ./ecs, ./klaxon, etc.).

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

data "aws_availability_zones" "azs" {}

resource "aws_subnet" "subnets" {
  count             = "${length(data.aws_availability_zones.azs.names)}"
  cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.azs.names[count.index]}"
  vpc_id            = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = true

  depends_on = ["aws_internet_gateway.gw"]

  lifecycle {
    ignore_changes = ["tags"]
  }
}

resource "aws_default_route_table" "r" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "route_ass" {
  count          = "${length(data.aws_availability_zones.azs.names)}"
  subnet_id      = "${element(aws_subnet.subnets.*.id, count.index)}"
  route_table_id = "${aws_default_route_table.r.id}"
}

resource "aws_default_vpc_dhcp_options" "default" {
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.vpc.id}"
  dhcp_options_id = "${aws_default_vpc_dhcp_options.default.id}"
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.vpc.default_network_acl_id}"
  subnet_ids             = ["${aws_subnet.subnets.*.id}"]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_route53_zone" "hosted_zone" {
  name          = "${var.domain}."
  comment       = ""
  force_destroy = false
}
