resource "aws_route53_zone" "kate_site" {
  name          = "katefeatherston.com"
  comment       = ""
  force_destroy = false
}

resource "aws_route53_record" "a_records" {
  zone_id = "${aws_route53_zone.kate_site.id}"
  name    = ""
  type    = "A"
  ttl     = "60"
  records = ["${var.squarespace_ips}"]
}

resource "aws_route53_record" "kate_site_verify" {
  zone_id = "${aws_route53_zone.kate_site.id}"
  name    = "www"
  type    = "CNAME"
  ttl     = "60"
  records = ["ext-cust.squarespace.com"]
}

resource "aws_route53_record" "kate_site_www" {
  zone_id = "${aws_route53_zone.kate_site.id}"
  name    = "rkgrstzkdzhss6gwbhw4"
  type    = "CNAME"
  ttl     = "60"
  records = ["verify.squarespace.com"]
}
