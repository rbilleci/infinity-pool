# See examples at: https://github.com/gruntwork-io/terragrunt-infrastructure-live-example/blob/main/root.hcl
locals {
  environment_variables = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  aws_region      = local.environment_variables.locals.aws_region
  deployment_name = local.environment_variables.locals.deployment_name
  deployment_key  = local.environment_variables.locals.deployment_key
  environment     = local.environment_variables.locals.environment
}

# Terraform State
remote_state {
  backend = "s3"
  config = {
    region         = "${local.aws_region}"
    dynamodb_table = "tf-locks-${get_aws_account_id()}-${local.deployment_key}"
    bucket         = "tf-state-${get_aws_account_id()}-${local.deployment_key}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}