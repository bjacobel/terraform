data "template_file" "influxdb_definition" {
  template = "${file("${path.module}/definitions/influxdb-definition.json")}"

  vars {
    influx_image = "library/influxdb"
    influx_container_name = "influxdb"
    log_group_region = "${var.region}"
    influx_log_group_name = "${aws_cloudwatch_log_group.influx.name}"
    influx_sitespeed_password = "${aws_ssm_parameter.influxdb_password.value}"
  }
}

resource "aws_ssm_parameter" "influxdb_password" {
  name  = "influxdb.password"
  type  = "SecureString"
  key_id = "${var.kms_key_id}"
  value = "Set to real value using awscli; not managed here"

  lifecycle {
    ignore_changes = ["value", "version"]
  }
}

resource "aws_ecs_task_definition" "influxdb" {
  family = "tf_tasks_influxdb"
  container_definitions = "${data.template_file.influxdb_definition.rendered}"

  volume {
    name = "influxdb-data"
    host_path = "/ecs/influxdb"
  }
}

resource "aws_ecs_service" "influxdb" {
  name = "tf-service-influxdb"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.influxdb.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "influx" {
  name = "influx"
}
