resource "aws_cloudwatch_log_group" "ipsec_group" {
  name = "ipsec"
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/templates/task.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.ipsec_group.name}"
    region = "${var.region}"
    VPN_IPSEC_PSK = "${var.VPN_IPSEC_PSK}"
    VPN_PASSWORD = "${var.VPN_PASSWORD}"
    VPN_USER = "${var.VPN_USER}"
  }
}

resource "aws_ecs_task_definition" "ipsec_defn" {
  family = "ipsec"
  container_definitions = "${data.template_file.task_definition.rendered}"

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
}
