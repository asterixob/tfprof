terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
# make sure to export AWS settings before tf plan or other ways lie profile and sso login
# region = "us-east-1"
# % export AWS_ACCESS_KEY_ID="anaccesskey"
# % export AWS_SECRET_ACCESS_KEY="asecretkey"
# % export AWS_REGION="us-west-2"
# % terraform plan
}
