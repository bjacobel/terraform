data "template_file" "grafana_definition" {
  template = "${file("${path.module}/definitions/grafana-definition.json")}"

  vars {
    grafana_image = "grafana/grafana"
    grafana_container_name = "grafana"
    log_group_region = "${var.aws_region}"
    grafana_log_group_name = "${aws_cloudwatch_log_group.grafana.name}"
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
  cluster = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.grafana.arn}"
  desired_count = 1
}

# Log Bits
resource "aws_cloudwatch_log_group" "grafana" {
  name = "grafana"
}
