resource "aws_cloudwatch_log_group" "klaxon_group" {
  name = "klaxon"
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name      = "${aws_cloudwatch_log_group.klaxon_group.name}"
    region              = "${var.region}"
    DATABASE_URL        = "${module.rds.rds_ctx_string}"
    ADMIN_EMAILS        = "${var.email}"
    AMAZON_SES_ADDRESS  = "${var.AMAZON_SES_ADDRESS}"
    AMAZON_SES_DOMAIN   = "${var.AMAZON_SES_DOMAIN}"
    AMAZON_SES_PASSWORD = "${aws_ssm_parameter.ses_password.value}"
    AMAZON_SES_USERNAME = "${aws_ssm_parameter.ses_username.value}"
    MAILER_FROM_ADDRESS = "${var.MAILER_FROM_ADDRESS}"
    SECRET_KEY_BASE     = "${aws_ssm_parameter.klaxon_secretkey.value}"
    SMTP_PROVIDER       = "${var.SMTP_PROVIDER}"
    cluster_name        = "${var.cluster_name}"
    domain_name         = "${var.domain}"
  }
}

resource "aws_ecs_task_definition" "klaxon_defn" {
  family                = "klaxon"
  container_definitions = "${data.template_file.container_definitions.rendered}"
}

resource "aws_service_discovery_service" "klaxon" {
  name = "klaxon"

  dns_config {
    namespace_id = "${var.service_registry_dns_namespace_id}"

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "klaxon_svc" {
  name                               = "klaxon"
  cluster                            = "${var.cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.klaxon_defn.arn}"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0

  service_registries {
    registry_arn   = "${aws_service_discovery_service.klaxon.arn}"
    container_name = "klaxon"
    container_port = 3000
  }
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

resource "aws_ssm_parameter" "ses_password" {
  name   = "klaxon.ses_password"
  type   = "SecureString"
  key_id = "${var.kms_key_id}"
  value  = "Set to real value using awscli; not managed here"

  lifecycle {
    ignore_changes = ["value", "version"]
  }
}

resource "aws_ssm_parameter" "ses_username" {
  name   = "klaxon.ses_username"
  type   = "SecureString"
  key_id = "${var.kms_key_id}"
  value  = "Set to real value using awscli; not managed here"

  lifecycle {
    ignore_changes = ["value", "version"]
  }
}

resource "aws_ssm_parameter" "klaxon_secretkey" {
  name   = "klaxon.secretkey"
  type   = "SecureString"
  key_id = "${var.kms_key_id}"
  value  = "Set to real value using awscli; not managed here"

  lifecycle {
    ignore_changes = ["value", "version"]
  }
}

module "rds" {
  name             = "klaxon"
  source           = "../rds"
  us-east-1-vpc-id = "${var.vpc_id}"
  username         = "rds"
  password         = "${aws_ssm_parameter.klaxon_secretkey.value}"
}
