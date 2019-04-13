output "rds_ctx_string" {
  value = "postgresql://${var.username}:${var.password}@${aws_rds_cluster.rds_db.endpoint}:${aws_rds_cluster.rds_db.port}"
}
