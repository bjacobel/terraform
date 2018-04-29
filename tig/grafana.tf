data "template_file" "grafana_definition" {
  template = "${file("${path.module}/definitions/grafana-definition.json")}"

  vars {
    grafana_image = "grafana/grafana:5.1.0"
    grafana_container_name = "grafana"
    log_group_region = "${var.region}"
    grafana_log_group_name = "${aws_cloudwatch_log_group.grafana.name}"
    admin_password = "${aws_ssm_parameter.grafana_password.value}"
  }
}

resource "aws_ssm_parameter" "grafana_password" {
  name  = "grafana.password"
  type  = "SecureString"
  key_id = "${var.kms_key_id}"
  value = "Set to real value using awscli; not managed here"

  lifecycle {
    ignore_changes = ["value", "version"]
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family = "grafana"
  container_definitions = "${data.template_file.grafana_definition.rendered}"

  volume {
    name = "grafana-sqlite"
    host_path = "/efs/grafana/sqlite"
  }
}

resource "aws_ecs_service" "grafana" {
  name = "grafana"
  cluster = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.grafana.arn}"
  desired_count = 1
}

resource "aws_cloudwatch_log_group" "grafana" {
  name = "grafana"
}

resource "aws_iam_role" "cloudwatch_ro" {
    name = "tf-ecs-service-role-grafana-cloudwatch-ro"
    max_session_duration = 43200

    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com",
        "AWS": "${var.instance_role_arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch_ro" {
    name = "tf-ecs-service-policy-grafana-cloudwatch-ro"
    role = "${aws_iam_role.cloudwatch_ro.name}"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:Get*",
        "cloudwatch:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
