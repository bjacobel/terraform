resource "aws_cloudwatch_log_group" "webserver_group" {
  name = "webserver"
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.webserver_group.name}"
    region = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "webserver_defn" {
  family = "webserver"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name = "caddy-root"
    host_path = "/efs/webserver/caddy-root"
  }
}

resource "aws_ecs_service" "webserver_svc" {
  name = "webserver"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.webserver_defn.arn}"
  desired_count = 1
}
