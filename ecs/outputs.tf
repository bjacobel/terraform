output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "kms_key_id" {
  value = "${aws_kms_key.ecs.id}"
}
