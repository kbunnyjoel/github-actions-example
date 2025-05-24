# Terraform module to create an S3 bucket for remote backend

provider "aws" {
  region = "ap-southeast-2" # Sydney
  
}
data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-eks-terraform-state${data.aws_caller_identity.current.account_id}"


  tags = {
    Name        = "TerraformState"
    Environment = "infra"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
