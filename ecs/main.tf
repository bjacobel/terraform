resource "aws_ecs_cluster" "cluster" {
  name = "${var.cluster_name}"
}

resource "aws_key_pair" "keypair" {
  key_name="${var.cluster_name}-key"
  public_key="${file("~/.ssh/${var.cluster_name}.pem")}"
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

  provisioner "file" {
    content = "${var.caddyfile}"
    destination = "/home/ec2-user/klaxon/Caddyfile"
  }

  // @TODO: Move this file inside the ipsec module
  user_data = <<EOF
#!/bin/bash
sudo modprobe af_key
EOF
}
