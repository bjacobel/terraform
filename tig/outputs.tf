output "cloudwatch_assume_role_arn" {
    value = "${aws_iam_role.cloudwatch_ro.arn}"
}
