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
    host_path = "/efs/gogs/data"
  }
}

resource "aws_service_discovery_service" "gogs" {
  name = "gogs"

  dns_config {
    namespace_id = "${var.service_registry_dns_namespace_id}"

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "gogs_svc" {
  name = "gogs"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.gogs_defn.arn}"
  desired_count = 1
  deployment_minimum_healthy_percent = 0

  service_registries {
    registry_arn  = "${aws_service_discovery_service.gogs.arn}"
    container_name = "gogs"
    container_port = 3000
  }
}
