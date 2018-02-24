module "ecs" {
  source = "./ecs"
  hosted_zone_name = "${aws_route53_zone.hosted_zone.name}"
  hosted_zone_id = "${aws_route53_zone.hosted_zone.zone_id}"
  subnet_id = "${aws_subnet.subnet.id}"
  vpc_id = "${aws_vpc.vpc.id}"
  cluster_name = "${var.cluster_name}"
  instance_type = "${var.instance_type}"
  klaxon_caddyfile = "${module.klaxon.caddyfile}"
  gitlab_caddyfile = "${module.gitlab.caddyfile}"
}

module "klaxon" {
  source = "./klaxon"
  hosted_zone_id = "${aws_route53_zone.hosted_zone.zone_id}"
  DATABASE_URL = "${var.DATABASE_URL}"
  AMAZON_SES_ADDRESS = "${var.AMAZON_SES_ADDRESS}"
  AMAZON_SES_DOMAIN = "${var.AMAZON_SES_DOMAIN}"
  MAILER_FROM_ADDRESS = "${var.MAILER_FROM_ADDRESS}"
  SMTP_PROVIDER = "${var.SMTP_PROVIDER}"
  AMAZON_SES_PASSWORD = "${var.AMAZON_SES_PASSWORD}"
  AMAZON_SES_USERNAME = "${var.AMAZON_SES_USERNAME}"
  SECRET_KEY_BASE = "${var.SECRET_KEY_BASE}"
  email = "${var.email}"
  domain = "${var.domain}"
  region = "${var.region}"
  cluster_name = "${var.cluster_name}"
  cluster_id = "${module.ecs.cluster_id}"
}

module "ipsec" {
  source = "./ipsec"
  region = "${var.region}"
  VPN_IPSEC_PSK = "${var.VPN_IPSEC_PSK}"
  VPN_PASSWORD = "${var.VPN_PASSWORD}"
  VPN_USER = "${var.VPN_USER}"
  cluster_id = "${module.ecs.cluster_id}"
}

module "webserver" {
  source = "./webserver"
  cluster_id = "${module.ecs.cluster_id}"
  email = "${var.email}"
  domain = "${var.domain}"
  region = "${var.region}"
  cluster_name = "${var.cluster_name}"
}

module "gitlab" {
  source = "./gitlab"
  cluster_id = "${module.ecs.cluster_id}"
  email = "${var.email}"
  domain = "${var.domain}"
  region = "${var.region}"
  cluster_name = "${var.cluster_name}"
}
