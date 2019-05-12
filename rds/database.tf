resource "aws_security_group" "rds_db" {
  vpc_id      = "${aws_vpc.vpc.id}"
  name        = "${var.name}-db-sg"
  description = "security group permitting access from ${var.name} app code to db"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = [
      "${data.aws_vpc.virginia.cidr_block}",
      "${aws_vpc.vpc.cidr_block}"
    ]
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

resource "aws_db_subnet_group" "rds_db" {
  name        = "${var.name}-db-subnet"
  description = "subnet for ${var.name} database in aurora"
  subnet_ids  = ["${aws_subnet.subnets.*.id}"]
}

resource "aws_rds_cluster" "rds_db" {
  cluster_identifier      = "klaxon-db"
  vpc_security_group_ids  = ["${aws_security_group.rds_db.id}"]
  db_subnet_group_name    = "${aws_db_subnet_group.rds_db.name}"
  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  engine_version          = "10.5"
  master_username         = "${var.username}"
  master_password         = "${var.password}"
  database_name           = "rds"
  backup_retention_period = 7
  skip_final_snapshot     = true

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 8
    min_capacity             = 8
    seconds_until_auto_pause = 300
  }

  lifecycle {
    ignore_changes = [
      "engine_version",
    ]
  }
}
