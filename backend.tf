terraform {
  required_version = "~> 1.13"
  backend "s3" {
    bucket       = "tasklog-tfstate-fj03rofcndasc8dsa"
    key          = "terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
