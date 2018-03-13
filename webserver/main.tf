resource "aws_cloudwatch_log_group" "webserver_group" {
  name = "webserver"
}

data "template_file" "caddyfile" {
  count    = "${length(var.services)}"
  template = "${file("${path.module}/../webserver/templates/Caddyfile")}"

  vars {
    cluster_name = "${var.cluster_name}"
    email        = "${var.email}"
    service      = "${lookup(var.services[count.index], "name")}"
    port         = "${lookup(var.services[count.index], "port")}"

    url = "${lookup(
      var.services[count.index],
      "url_override",
      format("https://%s", join(".", list(lookup(var.services[count.index], "name"), var.cluster_name, var.domain)))
    )}"
  }
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.webserver_group.name}"
    region         = "${var.region}"
    caddyfile      = "${replace(join("\\n\\n", data.template_file.caddyfile.*.rendered), "/\n/", "\\\\n")}"
  }
}

resource "aws_ecs_task_definition" "webserver_defn" {
  family                = "webserver"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name      = "caddy-root"
    host_path = "/efs/webserver/caddy-root"
  }
}

resource "aws_ecs_service" "webserver_svc" {
  name                               = "webserver"
  cluster                            = "${var.cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.webserver_defn.arn}"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
}
