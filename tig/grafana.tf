data "template_file" "grafana_definition" {
  template = "${file("${path.module}/definitions/grafana-definition.json")}"

  vars {
    grafana_image = "grafana/grafana"
    grafana_container_name = "grafana"
    log_group_region = "${var.region}"
    grafana_log_group_name = "${aws_cloudwatch_log_group.grafana.name}"
    admin_password = "${aws_ssm_parameter.grafana_password.value}"
  }
}

resource "aws_ssm_parameter" "grafana_password" {
  name  = "grafana.password"
  type  = "SecureString"
  key_id = "${var.kms_key_id}"
  value = "Set to real value using awscli; not managed here"

  lifecycle {
    ignore_changes = ["value", "version"]
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family = "grafana"
  container_definitions = "${data.template_file.grafana_definition.rendered}"

  volume {
    name = "grafana-sqlite"
    host_path = "/ecs/grafana/sqlite"
  }
}

resource "aws_ecs_service" "grafana" {
  name = "grafana"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.grafana.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "grafana" {
  name = "grafana"
}
