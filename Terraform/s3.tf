provider "aws" {
    region = "ap-south-1"
}

# s3 bucker
resource "aws_s3_bucket" "terraform-bucket" {
    bucket = "our-terraform-tfstate-file-bucket-shubham"
    tags = {
        Name = "first-bucket"
        Env = "Dev"
        Owner = "Shubham"
        bucket = "mainBucket"
    }
  
}
# versioning
resource "aws_s3_bucket_versioning" "my-bucket-versioning" {
  bucket = aws_s3_bucket.terraform-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}