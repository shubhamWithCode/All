provider "aws" {
    region = "ap-south-1"
}

# s3 bucker
resource "aws_s3_bucket" "terraform-bucket" {
    bucket = "our-terraform-tfstate-file-bucket-shubham"
}
resource "aws_s3_bucket_acl""terraform-bucket-acl"{
bucket = aws_s3_bucket.terrafrom-bucket.id
acl="private"
}

  
}

# versioning
resource "aws_s3_bucket_versioning" "my-bucket-versioning" {
  bucket = aws_s3_bucket.terraform-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
