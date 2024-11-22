terraform {
  backend "s3" {
    bucket = "terraform-021891574607"
    key    = "tfstate"
    region = "eu-west-2"
  }
}