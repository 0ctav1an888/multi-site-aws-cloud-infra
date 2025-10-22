terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket         = ""
    key            = ""
    region         = ""
    dynamodb_table = "terraform-locks"
  }
}