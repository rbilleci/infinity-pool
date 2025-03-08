terraform {
  source = "../terraform"
}

locals {
  account_id = trimspace(run_cmd("aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text"))
}

inputs = {
  aws_region                = "eu-west-1"
  cluster_name              = "infinity-pool-eks"
  aurora_cluster_identifier = "infinity-pool-db"
  db_username               = "postgres"
  db_password               = get_env("DB_PASSWORD")
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "tf-state-${local.account_id}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
