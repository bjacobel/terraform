resource "aws_cloudwatch_log_group" "klaxon_group" {
  name = "klaxon"
}

data "template_file" "caddyfile" {
  template = "${file("${path.module}/../webserver/templates/Caddyfile")}"

  vars {
    cluster_name = "${var.cluster_name}"
    domain = "${var.domain}"
    email = "${var.email}"
    service = "klaxon"
    port = 3000
  }
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.klaxon_group.name}"
    region = "${var.region}"
    DATABASE_URL = "${var.DATABASE_URL}"
    ADMIN_EMAILS = "${var.email}"
    AMAZON_SES_ADDRESS = "${var.AMAZON_SES_ADDRESS}"
    AMAZON_SES_DOMAIN = "${var.AMAZON_SES_DOMAIN}"
    AMAZON_SES_PASSWORD = "${var.AMAZON_SES_PASSWORD}"
    AMAZON_SES_USERNAME = "${var.AMAZON_SES_USERNAME}"
    MAILER_FROM_ADDRESS = "${var.MAILER_FROM_ADDRESS}"
    SECRET_KEY_BASE = "${var.SECRET_KEY_BASE}"
    SMTP_PROVIDER = "${var.SMTP_PROVIDER}"
    cluster_name = "${var.cluster_name}"
    domain_name = "${var.domain}"
  }
}

resource "aws_ecs_task_definition" "klaxon_defn" {
  family = "klaxon"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name = "postgres-data"
    host_path = "/efs/klaxon/postgres-data"
  }
}

resource "aws_ecs_service" "klaxon_svc" {
  name = "klaxon"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.klaxon_defn.arn}"
  desired_count = 0
}

resource "aws_ses_domain_identity" "ses_domain" {
  domain = "${var.domain}"
}

resource "aws_route53_record" "amazonses_verification_record" {
  zone_id = "${var.hosted_zone_id}"
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "60"
  records = ["${aws_ses_domain_identity.ses_domain.verification_token}"]
}
