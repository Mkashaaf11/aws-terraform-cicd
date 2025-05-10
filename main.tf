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

#   backend "s3" {
#     bucket  = "your-terraform-state-bucket" # Replace with your S3 bucket name
#     key     = "terraform/state/terraform.tfstate"
#     region  = "ap-southeast-1"
#     encrypt = true
#   }

resource "random_id" "unique_id" {
  byte_length = 4
}

# S3 Bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "bucketfordevops-${random_id.unique_id.hex}"
  tags   = { Name = "My Secure S3 Bucket" }
}

resource "aws_s3_bucket_ownership_controls" "example_bucket" {
  bucket = aws_s3_bucket.example_bucket.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "example_bucket" {
  bucket                  = aws_s3_bucket.example_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "example_bucket" {
  bucket = aws_s3_bucket.example_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example_bucket" {
  bucket = aws_s3_bucket.example_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# VPC
resource "aws_vpc" "example_vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "MyExampleVPC" }
}

resource "aws_subnet" "example_subnet_a" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = "ap-southeast-1a"
  tags              = { Name = "MyExampleSubnetA" }
}

resource "aws_subnet" "example_subnet_b" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.0.16/28"
  availability_zone = "ap-southeast-1b"
  tags              = { Name = "MyExampleSubnetB" }
}

# Security Group for EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.example_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to your IP for better security
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "EC2 SG" }
}

# EC2 Instance (Private, no public IP)
resource "aws_instance" "example_ec2" {
  ami                         = "ami-0f02b24005e4aec36" # Amazon Linux 2, x86_64
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.example_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false # No public IP
  tags                        = { Name = "MyExampleEC2" }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.example_vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id] # EC2 can access RDS
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "RDS SG" }
}

# RDS Instance
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "example-rds"
  subnet_ids = [aws_subnet.example_subnet_a.id, aws_subnet.example_subnet_b.id]
  tags       = { Name = "MyExampleRDSSubnet" }
}

# resource "aws_db_instance" "example_rds" {
#   allocated_storage      = 20
#   engine                 = "mysql"
#   instance_class         = "db.t3.micro"
#   db_name                = "exampledb"
#   username               = "admin"
#   password               = "password1234"
#   db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   skip_final_snapshot    = true
#   publicly_accessible    = false
#   tags                   = { Name = "MyExampleRDS" }
# }

data "aws_caller_identity" "current" {}
