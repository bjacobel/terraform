output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "kms_key_id" {
  value = "${aws_kms_key.ecs.id}"
}

output "cluster_ip" {
  value = "${aws_eip.static_ip.public_ip}"
}

output "instance_role_arn" {
  value = "${aws_iam_role.ecs_role.arn}"
}
