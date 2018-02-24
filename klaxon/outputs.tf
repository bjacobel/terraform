output "caddyfile" {
  value = "${data.template_file.caddyfile.rendered}"
}
