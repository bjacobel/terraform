resource "aws_security_group" "klaxon_db" {
  vpc_id      = "${var.vpc_id}"
  name        = "klaxon-db-sg"
  description = "security group permitting access from klaxon task to db"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    security_groups = ["${var.security_group_id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "klaxon_db" {
  name        = "klaxon-db-subnet"
  description = "subnet for klaxon database in aurora"
  subnet_ids  = ["${var.subnet_id}"]
}

resource "aws_rds_cluster" "klaxon_db" {
  cluster_identifier      = "klaxon-db"
  vpc_security_group_ids  = ["${aws_security_group.klaxon_db.id}"]
  db_subnet_group_name    = "${aws_db_subnet_group.klaxon_db.name}"
  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  master_username         = "klaxon"
  master_password         = "${aws_ssm_parameter.klaxon_secretkey.value}"
  backup_retention_period = 7
  skip_final_snapshot     = false

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 2
    min_capacity             = 2
    seconds_until_auto_pause = 300
  }

  lifecycle {
    ignore_changes = [
      "engine_version",
    ]
  }
}
