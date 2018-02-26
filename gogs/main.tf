resource "aws_cloudwatch_log_group" "gogs_group" {
  name = "gogs"
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.gogs_group.name}"
    region = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "gogs_defn" {
  family = "gogs"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name = "data"
    host_path = "/efs/klaxon/data"
  }

  volume {
    name = "config"
    host_path = "/efs/klaxon/config"
  }
}

resource "aws_ecs_service" "gogs_svc" {
  name = "gogs"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.gogs_defn.arn}"
  desired_count = 1
  deployment_minimum_healthy_percent = 0
}
