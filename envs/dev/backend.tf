terraform {
  required_version = ">= 1.10"
  backend "s3" {
    bucket       = "joel-portfolio-tfstate-4821"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true   # S3-native state locking
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
