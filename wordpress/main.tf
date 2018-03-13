resource "aws_cloudwatch_log_group" "wordpress_group" {
  name = "wordpress"
}

resource "aws_cloudwatch_log_group" "mysql_group" {
  name = "mysql"
}

resource "random_string" "password" {
  length  = 20
  special = false
}

data "template_file" "container_definitions" {
  template = "${file("${path.module}/templates/containers.json")}"

  vars {
    wordpress_log_group_name = "${aws_cloudwatch_log_group.wordpress_group.name}"
    mysql_log_group_name     = "${aws_cloudwatch_log_group.mysql_group.name}"
    region                   = "${var.region}"
    db_pw                    = "${random_string.password.result}"
  }
}

resource "aws_ecs_task_definition" "wordpress_defn" {
  family                = "wordpress"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name      = "wp_data"
    host_path = "/efs/wordpress/wpcore/data"
  }

  volume {
    name      = "mysql_data"
    host_path = "/efs/wordpress/mysql/data"
  }
}

resource "aws_ecs_service" "wordpress_svc" {
  name                               = "wordpress"
  cluster                            = "${var.cluster_id}"
  task_definition                    = "${aws_ecs_task_definition.wordpress_defn.arn}"
  desired_count                      = 0
  deployment_minimum_healthy_percent = 0
}
