resource "aws_ecs_cluster" "cluster" {
  name = "${var.cluster_name}"
}

resource "aws_key_pair" "keypair" {
  key_name="xen"
  public_key="${file("~/.ssh/xen.pub")}"
}

resource "aws_route53_record" "cluster_dot" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.cluster_name}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ecs_host.public_ip}"]
}

resource "aws_route53_record" "service_dot_cluster_dot" {
  zone_id = "${var.hosted_zone_id}"
  name    = "*.${var.cluster_name}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ecs_host.public_ip}"]
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "ecsInstanceRole"
  role = "ecsInstanceRole"
}

resource "aws_iam_role" "ecs_role" {
  name = "ecsInstanceRole"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_efs_file_system" "ecs_efs" {}

resource "aws_efs_mount_target" "ecs_efs_mount" {
  file_system_id = "${aws_efs_file_system.ecs_efs.id}"
  subnet_id      = "${var.subnet_id}"
  security_groups = ["${aws_security_group.nfs_group.id}"]
}

resource "aws_instance" "ecs_host" {
  key_name = "${aws_key_pair.keypair.key_name}"
  ami = "ami-031507b307be48f22"  // us-east-1 amzn-ami-2018.03.k-amazon-ecs-optimized
  instance_type = "${var.instance_type}"
  subnet_id  = "${var.subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.ecs_group.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs_profile.name}"
  # ebs_optimized = true

  tags {
    Cluster = "${var.cluster_name}"
  }

  user_data = <<EOF
${data.template_file.user_data.rendered}
EOF

  provisioner "remote-exec" {
    inline = [
      "sudo modprobe af_key",  # module needed for ipsec
    ]

    connection {
      user = "ec2-user"
      private_key = "${file("~/.ssh/xen")}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    cluster_name = "${aws_ecs_cluster.cluster.name}"
    efs_dns_name = "${aws_efs_mount_target.ecs_efs_mount.dns_name}"
  }
}

resource "aws_kms_key" "ecs" {
  description = "Encrypts secrets used in the ${aws_ecs_cluster.cluster.name} ECS cluster"
}

resource "aws_service_discovery_private_dns_namespace" "internal" {
  vpc         = "${var.vpc_id}"
  name        = "xen.internal"
  description = "internal DNS SD for xen cluster"
}
