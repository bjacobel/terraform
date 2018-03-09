data "template_file" "influxdb_definition" {
  template = "${file("${path.module}/definitions/influxdb-definition.json")}"

  vars {
    influx_image = "library/influxdb"
    influx_container_name = "influxdb"
    log_group_region = "${var.aws_region}"
    influx_log_group_name = "${aws_cloudwatch_log_group.influx.name}"
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
  cluster = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.influxdb.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "influx" {
  name = "influx"
}
