data "template_file" "scheduler_task_definition" {
  template = "${file("${path.module}/templates/scheduler.json")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.klaxon_group.name}"
    region = "${var.region}"
    // When Postgres Aurora Serverless exits preview, this can be `aws_rds_cluster.klaxon_db.endpoint`
    DATABASE_URL = "postgresql://klaxon:${aws_ssm_parameter.klaxon_secretkey.value}@${"klaxon-db.cluster-cyeuxymacsh3.us-east-2.rds.amazonaws.com"}:5432"
  }
}

resource "aws_ecs_task_definition" "scheduler" {
  family = "klaxon-scheduler"
  container_definitions = "${data.template_file.scheduler_task_definition.rendered}"
}

resource "aws_cloudwatch_event_rule" "scheduler" {
  name        = "klaxon-scheduler"
  description = "Run klaxon snapshotter every 10min"
  schedule_expression = "rate(10 minutes)"
  is_enabled = true
}

data "aws_caller_identity" "current" {}


resource "aws_cloudwatch_event_target" "scheduler" {
  target_id = "klaxon-scheduler"
  rule = "${aws_cloudwatch_event_rule.scheduler.name}"
  arn = "${var.cluster_id}"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsEventsRole"
  input = "{}"

  ecs_target {
    task_count = 1
    task_definition_arn = "${aws_ecs_task_definition.scheduler.arn}"
  }
}
