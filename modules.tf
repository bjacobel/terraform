module "ecs" {
  source = "./ecs"
  hosted_zone_name = "${aws_route53_zone.hosted_zone.name}"
  hosted_zone_id = "${aws_route53_zone.hosted_zone.zone_id}"
  subnet_id = "${aws_subnet.subnet.id}"
  vpc_id = "${aws_vpc.vpc.id}"
  cluster_name = "${var.cluster_name}"
  instance_type = "${var.instance_type}"
  klaxon_caddyfile = "${module.klaxon.caddyfile}"
  gogs_caddyfile = "${module.gogs.caddyfile}"
}

module "klaxon" {
  source = "./klaxon"
  hosted_zone_id = "${aws_route53_zone.hosted_zone.zone_id}"
  DATABASE_URL = "${var.DATABASE_URL}"
  AMAZON_SES_ADDRESS = "${var.AMAZON_SES_ADDRESS}"
  AMAZON_SES_DOMAIN = "${var.AMAZON_SES_DOMAIN}"
  MAILER_FROM_ADDRESS = "${var.MAILER_FROM_ADDRESS}"
  SMTP_PROVIDER = "${var.SMTP_PROVIDER}"
  email = "${var.email}"
  domain = "${var.domain}"
  region = "${var.region}"
  cluster_name = "${var.cluster_name}"
  cluster_id = "${module.ecs.cluster_id}"
  kms_key_id = "${module.ecs.kms_key_id}"
}

module "ipsec" {
  source = "./ipsec"
  region = "${var.region}"
  cluster_id = "${module.ecs.cluster_id}"
  kms_key_id = "${module.ecs.kms_key_id}"
}

module "webserver" {
  source = "./webserver"
  cluster_id = "${module.ecs.cluster_id}"
  email = "${var.email}"
  domain = "${var.domain}"
  region = "${var.region}"
  cluster_name = "${var.cluster_name}"
}

module "gogs" {
  source = "./gogs"
  cluster_id = "${module.ecs.cluster_id}"
  email = "${var.email}"
  domain = "${var.domain}"
  region = "${var.region}"
  cluster_name = "${var.cluster_name}"
}

module "dnsdock" {
  source = "./dnsdock"
  region = "${var.region}"
  cluster_id = "${module.ecs.cluster_id}"
}
