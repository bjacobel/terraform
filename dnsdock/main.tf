resource "aws_cloudwatch_log_group" "dnsdock_group" {
  name = "dnsdock"
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.dnsdock_group.name}"
    region = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "dnsdock_defn" {
  family = "dnsdock"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name = "docker-sock"
    host_path = "/var/run/docker.sock"
  }
}

resource "aws_ecs_service" "dnsdock_svc" {
  name = "dnsdock"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.dnsdock_defn.arn}"
  desired_count = 1
  deployment_minimum_healthy_percent = 0
}
