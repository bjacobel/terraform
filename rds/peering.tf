data "aws_caller_identity" "current" {}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

resource "aws_vpc_peering_connection" "ohio_virginia" {
  provider      = "aws.virginia"
  peer_owner_id = "${data.aws_caller_identity.current.account_id}"
  peer_vpc_id   = "${aws_vpc.vpc.id}"
  vpc_id        = "${var.us-east-1-vpc-id}"
  peer_region   = "us-east-2"
  auto_accept   = false
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.ohio_virginia.id}"
  auto_accept               = true
}

resource "aws_vpc_peering_connection_options" "ctx_opts" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.ohio_virginia.id}"
  depends_on                = ["aws_vpc_peering_connection_accepter.peer"]

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

data "aws_vpc" "virginia" {
  provider = "aws.virginia"
  id       = "${var.us-east-1-vpc-id}"
}

resource "aws_route" "ohio_to_virginia" {
  route_table_id            = "${aws_default_route_table.r.id}"
  destination_cidr_block    = "${data.aws_vpc.virginia.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.ohio_virginia.id}"

  depends_on = [
    "aws_vpc_peering_connection_accepter.peer",
  ]
}

data "aws_route_table" "virginia" {
  provider  = "aws.virginia"
  vpc_id = "${var.us-east-1-vpc-id}"
}

resource "aws_route" "virginia_to_ohio" {
  provider                  = "aws.virginia"
  route_table_id            = "${data.aws_route_table.virginia.id}"
  destination_cidr_block    = "${aws_vpc.vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.ohio_virginia.id}"

  depends_on = [
    "aws_vpc_peering_connection_accepter.peer",
  ]
}
