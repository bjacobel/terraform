output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "kms_key_id" {
  value = "${aws_kms_key.ecs.id}"
}

output "cluster_ip" {
  value = "${aws_instance.ecs_host.public_ip}"
}

output "instance_role_arn" {
  value = "${aws_iam_role.ecs_role.arn}"
}

output "service_registry_dns_namespace_id" {
  value = "${aws_service_discovery_private_dns_namespace.internal.id}"
}

output "security_group_id" {
  value = "${aws_security_group.ecs_group.id}"
}
