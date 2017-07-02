provider "aws" {
  region = "${var.region}"
  profile = "bjacobel"
}

// The lines below set up common infra; everything you need to do anything interesting in AWS.
// The actual interesting stuff is in the modules (e.g., ./ecs, ./klaxon, etc.).

resource "aws_vpc" "vpc" {
  cidr_block = "172.31.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_subnet" "subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "172.31.0.0/20"
  map_public_ip_on_launch = true

  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_route53_zone" "hosted_zone" {
  name = "${var.domain}."
}
