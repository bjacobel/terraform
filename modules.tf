module "ecs" {
  source           = "./ecs"
  hosted_zone_name = "${aws_route53_zone.hosted_zone.name}"
  hosted_zone_id   = "${aws_route53_zone.hosted_zone.zone_id}"
  subnet_id        = "${aws_subnet.subnet.id}"
  vpc_id           = "${aws_vpc.vpc.id}"
  cluster_name     = "${var.cluster_name}"
  instance_type    = "${var.instance_type}"
}

module "klaxon" {
  source              = "./klaxon"
  hosted_zone_id      = "${aws_route53_zone.hosted_zone.zone_id}"
  DATABASE_URL        = "${var.DATABASE_URL}"
  AMAZON_SES_ADDRESS  = "${var.AMAZON_SES_ADDRESS}"
  AMAZON_SES_DOMAIN   = "${var.AMAZON_SES_DOMAIN}"
  MAILER_FROM_ADDRESS = "${var.MAILER_FROM_ADDRESS}"
  SMTP_PROVIDER       = "${var.SMTP_PROVIDER}"
  email               = "${var.email}"
  domain              = "${var.domain}"
  region              = "${var.region}"
  cluster_name        = "${var.cluster_name}"
  cluster_id          = "${module.ecs.cluster_id}"
  kms_key_id          = "${module.ecs.kms_key_id}"
}

module "ipsec" {
  source     = "./ipsec"
  region     = "${var.region}"
  cluster_id = "${module.ecs.cluster_id}"
  kms_key_id = "${module.ecs.kms_key_id}"
}

module "webserver" {
  source       = "./webserver"
  cluster_id   = "${module.ecs.cluster_id}"
  email        = "${var.email}"
  domain       = "${var.domain}"
  region       = "${var.region}"
  cluster_name = "${var.cluster_name}"

  services = [
    {
      name = "klaxon"
      port = "3000"
    },
    {
      name = "gogs"
      port = "3000"
    },
    {
      name = "grafana"
      port = "3000"
    },
    {
      name = "influxdb"
      port = "8086"
    }
  ]
}

module "gogs" {
  source       = "./gogs"
  cluster_id   = "${module.ecs.cluster_id}"
  email        = "${var.email}"
  domain       = "${var.domain}"
  region       = "${var.region}"
  cluster_name = "${var.cluster_name}"
}

module "dnsdock" {
  source     = "./dnsdock"
  region     = "${var.region}"
  cluster_id = "${module.ecs.cluster_id}"
}

module "katefeatherstondotcom" {
  source = "./katefeatherston.com"
  squarespace_ips = [
    "198.185.159.144",
    "198.185.159.145",
    "198.49.23.144",
    "198.49.23.145"
  ]
}

module "tig" {
  source     = "./tig"
  region     = "${var.region}"
  cluster_id = "${module.ecs.cluster_id}"
  kms_key_id = "${module.ecs.kms_key_id}"
  instance_role_arn = "${module.ecs.instance_role_arn}"
}
