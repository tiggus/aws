terraform {
  backend "s3" {
    bucket  = "terraform-state-bbe7081d03a226fd"
    key     = "terraform/tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
