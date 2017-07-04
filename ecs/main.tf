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

resource "aws_instance" "ecs_host" {
  key_name = "${aws_key_pair.keypair.key_name}"
  ami = "ami-04351e12"  // us-east-1 amzn-ami-2017.03.d-amazon-ecs-optimized
  instance_type = "${var.instance_type}"
  private_ip = "172.31.0.246"
  subnet_id  = "${var.subnet_id}"
  security_groups = ["${aws_security_group.ecs_group.id}"]

  // for webserver
  provisioner "file" {
    content = "${var.caddyfile}"
    destination = "/home/ec2-user/klaxon/Caddyfile"
  }

  // for ipsec vpn
  provisioner "remote-exec" {
    inline = [
      "sudo modprobe af_key"
    ]
  }
}

resource "aws_security_group" "ecs_group" {
  name        = "ecs_group"

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = ["pl-12c4e678"]
  }
}
