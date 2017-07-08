resource "aws_ecs_cluster" "cluster" {
  name = "${var.cluster_name}"
}

resource "aws_key_pair" "keypair" {
  key_name="ec2-key"
  public_key="${file("~/.ssh/ec2-bjacobel.pub")}"
}

resource "aws_eip" "static_ip" {
  vpc = true
  instance = "${aws_instance.ecs_host.id}"
  associate_with_private_ip = "${aws_instance.ecs_host.private_ip}"
}

resource "aws_route53_record" "cluster_dot" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.cluster_name}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.static_ip.public_ip}"]
}

resource "aws_route53_record" "service_dot_cluster_dot" {
  zone_id = "${var.hosted_zone_id}"
  name    = "*.${var.cluster_name}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.static_ip.public_ip}"]
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
  ami = "ami-04351e12"  // us-east-1 amzn-ami-2017.03.d-amazon-ecs-optimized
  instance_type = "${var.instance_type}"
  private_ip = "172.31.0.246"
  subnet_id  = "${var.subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.ecs_group.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs_profile.name}"

  // for webserver
  provisioner "file" {
    content = "${var.caddyfile}"
    destination = "/efs/webserver/caddy-root/Caddyfile"

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("~/.ssh/ec2-bjacobel")}"
    }
  }

  // for ipsec vpn
  provisioner "remote-exec" {
    inline = [
      "sudo modprobe af_key",
    ]

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("~/.ssh/ec2-bjacobel")}"
    }
  }

  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config

yum install -y nfs-utils
mkdir -p /efs
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
    ${aws_efs_mount_target.ecs_efs_mount.dns_name}:/ /efs
chown 1000:1000 /efs
EOF

  root_block_device {
    volume_size = 8
  }
}
