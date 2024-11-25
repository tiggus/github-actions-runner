terraform {
  backend "s3" {
    bucket = "terraform-008971664666"
    key    = "tfstate"
    region = "eu-west-2"
  }
}