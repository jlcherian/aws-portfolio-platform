terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "joel-portfolio-tfstate-4821"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}