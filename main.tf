provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

resource "random_id" "unique_id" {
  byte_length = 4  # 4 bytes = 8 characters
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "bucketfordevops-${random_id.unique_id.hex}"

  tags = {
    Name        = "My Secure S3 Bucket"
    Environment = "Development"
  }
}

resource "aws_s3_bucket_ownership_controls" "example_bucket" {
  bucket = aws_s3_bucket.example_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "example_bucket" {
  bucket = aws_s3_bucket.example_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "example_bucket" {
  bucket = aws_s3_bucket.example_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example_bucket" {
  bucket = aws_s3_bucket.example_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "example_bucket_policy" {
  bucket = aws_s3_bucket.example_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.example_bucket.arn}/*"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_ownership_controls.example_bucket]
}

data "aws_caller_identity" "current" {}