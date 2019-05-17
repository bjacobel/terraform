module "ecs" {
  source           = "./ecs"
  hosted_zone_name = "${aws_route53_zone.hosted_zone.name}"
  hosted_zone_id   = "${aws_route53_zone.hosted_zone.zone_id}"
  subnet_id        = "${element(aws_subnet.subnets.*.id, 0)}"
  vpc_id           = "${aws_vpc.vpc.id}"
  cluster_name     = "${var.cluster_name}"
  instance_type    = "${var.instance_type}"
  price_cap        = "${var.price_cap}"
}

module "klaxon" {
  source               = "./klaxon"
  subnets              = ["${slice(aws_subnet.subnets.*.id, 0, 2)}"]
  vpc_id               = "${aws_vpc.vpc.id}"
  security_group_id    = "${module.ecs.security_group_id}"
  hosted_zone_id       = "${aws_route53_zone.hosted_zone.zone_id}"
  AMAZON_SES_ADDRESS   = "${var.AMAZON_SES_ADDRESS}"
  AMAZON_SES_DOMAIN    = "${var.AMAZON_SES_DOMAIN}"
  MAILER_FROM_ADDRESS  = "${var.MAILER_FROM_ADDRESS}"
  SMTP_PROVIDER        = "${var.SMTP_PROVIDER}"
  email                = "${var.email}"
  domain               = "${var.domain}"
  region               = "${var.region}"
  cluster_name         = "${var.cluster_name}"
  cluster_id           = "${module.ecs.cluster_id}"
  kms_key_id           = "${module.ecs.kms_key_id}"
  service_registry_dns_namespace_id = "${module.ecs.service_registry_dns_namespace_id}"
}

module "ipsec" {
  source     = "./ipsec"
  region     = "${var.region}"
  cluster_id = "${module.ecs.cluster_id}"
  kms_key_id = "${module.ecs.kms_key_id}"
  service_registry_dns_namespace_id = "${module.ecs.service_registry_dns_namespace_id}"
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
    },
    # {
    #   name = "gogs"
    # },
    {
      name = "grafana"
    },
    {
      name = "influxdb"
    }
  ]
}

# module "gogs" {
#   source       = "./gogs"
#   cluster_id   = "${module.ecs.cluster_id}"
#   email        = "${var.email}"
#   domain       = "${var.domain}"
#   region       = "${var.region}"
#   cluster_name = "${var.cluster_name}"
#   service_registry_dns_namespace_id = "${module.ecs.service_registry_dns_namespace_id}"
# }

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
  service_registry_dns_namespace_id = "${module.ecs.service_registry_dns_namespace_id}"
}
