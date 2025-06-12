# store the terraform state file in s3 and lock with dynamodb
terraform {
  backend "s3" {
    bucket         = "bucket-2-tier"
    key            = "2-tier-project/terraform.tfstate"
    region         = "eu-central-1"
    profile        = "terraform-user"
    dynamodb_table = "terraform-state-lock-2-tier"
  }
}