terraform {
  backend "s3" {
    bucket = "shubhams-s3-bucket"
    region = "ap-south-1"
    key = "eks/terraform.tfstate"
  }
}