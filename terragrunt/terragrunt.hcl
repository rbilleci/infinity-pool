terraform {
  source = "../terraform"
}

inputs = {
  aws_region                = "eu-west-1"
  cluster_name              = "infinity-pool-eks"
  aurora_cluster_identifier = "infinity-pool-db"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "tf-state-${get_env("AWS_ACCOUNT_ID")}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
