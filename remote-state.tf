resource "aws_s3_bucket" "state" {
  bucket = "bjacobel-terraform-state"
  acl    = "private"
}

terraform {
  required_version = ">= 0.10.1"

  backend "s3" {
    bucket  = "bjacobel-terraform-state"
    key = "terraform.tfstate"
    region  = "us-east-1"
  }
}
