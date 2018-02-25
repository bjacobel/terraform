resource "aws_cloudwatch_log_group" "ipsec_group" {
  name = "ipsec"
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.ipsec_group.name}"
    region = "${var.region}"
    VPN_IPSEC_PSK = "${aws_ssm_parameter.vpn_ipsec_psk.value}"
    VPN_PASSWORD = "${aws_ssm_parameter.vpn_password.value}"
    VPN_USER = "bjacobel"
  }
}

resource "aws_ecs_task_definition" "ipsec_defn" {
  family = "ipsec"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name = "modules"
    host_path = "/lib/modules"
  }
}

resource "aws_ecs_service" "ipsec_svc" {
  name = "ipsec"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.ipsec_defn.arn}"
  desired_count = 1
  deployment_minimum_healthy_percent = 0
}

resource "aws_ssm_parameter" "vpn_password" {
  name  = "vpn.password"
  type  = "SecureString"
  key_id = "${var.kms_key_id}"
  value = "Set to real value using awscli; not managed here"

  lifecycle {
      ignore_changes = ["value", "version"]
  }
}

resource "aws_ssm_parameter" "vpn_ipsec_psk" {
  name  = "vpn.ipsec_psk"
  type  = "SecureString"
  key_id = "${var.kms_key_id}"
  value = "Set to real value using awscli; not managed here"

  lifecycle {
      ignore_changes = ["value", "version"]
  }
}
