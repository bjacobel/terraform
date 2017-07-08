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

data "template_file" "caddyfile" {
  template = "${file("${path.module}/templates/Caddyfile")}"

  vars {
    cluster_name = "${var.cluster_name}"
    domain = "${var.domain}"
    email = "${var.email}"
  }
}

resource "aws_ecs_task_definition" "webserver_defn" {
  family = "webserver"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name = "caddy-root"
    host_path = "/home/ec2-user/klaxon/caddy-root"
  }

  volume {
    name = "dot-caddy"
    host_path = "/home/ec2-user/klaxon/dot-caddy"
  }
}

resource "aws_ecs_service" "webserver_svc" {
  name = "webserver"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.webserver_defn.arn}"
  desired_count = 0
}
