data "template_file" "task_definition" {
  template = "${file("${path.module}/templates/task.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.klaxon.name}"
    region = "${var.region}"
    DATABASE_URL = "${var.DATABASE_URL}"
    ADMIN_EMAILS = "${var.email}"
    POSTGRES_USER = "${var.POSTGRES_USER}"
    AMAZON_SES_ADDRESS = "${var.AMAZON_SES_ADDRESS}"
    AMAZON_SES_DOMAIN = "${var.AMAZON_SES_DOMAIN}"
    AMAZON_SES_PASSWORD = "${var.AMAZON_SES_PASSWORD}"
    AMAZON_SES_USERNAME = "${var.AMAZON_SES_USERNAME}"
    MAILER_FROM_ADDRESS = "${var.MAILER_FROM_ADDRESS}"
    SECRET_KEY_BASE = "${var.SECRET_KEY_BASE}"
    SMTP_PROVIDER = "${var.SMTP_PROVIDER}"
  }
}

data "template_file" "caddyfile" {
  template = "${file("${path.module}/../klaxon/templates/Caddyfile")}"

  vars {
    cluster_name = "${var.cluster_name}"
    domain = "${var.domain}"
    email = "${var.email}"
  }
}

resource "aws_cloudwatch_log_group" "klaxon" {
  name = "klaxon"
}

resource "aws_ecs_task_definition" "klaxon" {
  family = "klaxon"
  container_definitions = "${data.template_file.task_definition.rendered}"

  volume {
    name = "Caddyfile"
    host_path = "/home/ec2-user/klaxon/Caddyfile"
  }

  volume {
    name = "postgres-data"
    host_path = "/home/ec2-user/klaxon/postgres-data"
  }

  volume {
    name = "dot-caddy"
    host_path = "/home/ec2-user/klaxon/dot-caddy"
  }
}

resource "aws_ecs_service" "klaxon" {
  name = "klaxon"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.klaxon.arn}"
  desired_count = 1
}

resource "aws_ses_domain_identity" "ses_domain" {
  domain = "${var.domain}"
}

resource "aws_route53_record" "amazonses_verification_record" {
  zone_id = "${var.hosted_zone_id}"
  name    = "_amazonses.example.com"
  type    = "TXT"
  ttl     = "60"
  records = ["${aws_ses_domain_identity.ses_domain.verification_token}"]
}
