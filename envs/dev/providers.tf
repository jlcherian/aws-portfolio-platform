provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "aws-portfolio-platform"
      Environment = "dev"
      Owner       = "joel"
    }
  }
}