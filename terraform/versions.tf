terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  #   backend "s3" {
  #     bucket = "cloudterms-state-bucket"
  #     key    = "data_pipeline.tfstate"
  #     region = "ap-northeast-1"
  #   }
}

provider "aws" {
  region = "ap-northeast-1"
}
