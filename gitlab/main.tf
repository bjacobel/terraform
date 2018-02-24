resource "aws_cloudwatch_log_group" "gitlab_group" {
  name = "gitlab"
}

data "template_file" "caddyfile" {
  template = "${file("${path.module}/../webserver/templates/Caddyfile")}"

  vars {
    cluster_name = "${var.cluster_name}"
    domain = "${var.domain}"
    email = "${var.email}"
    service = "gitlab"
    port = 8080
  }
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.gitlab_group.name}"
    region = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "gitlab_defn" {
  family = "gitlab"
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

resource "aws_ecs_service" "gitlab_svc" {
  name = "gitlab"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.gitlab_defn.arn}"
  desired_count = 1
}
