
terraform {
  backend "s3" {
    bucket       = "pulse-state-new-4821"
    key          = "pulse-platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
