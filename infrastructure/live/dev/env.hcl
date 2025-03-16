locals {
  aws_region = get_env("AWS_REGION", "eu-west-1")
  deployment_name = lower(replace(get_env("DEPLOYMENT_NAME", "infinity-pool"), "[._ ]", "-"))
  deployment_key = "${local.deployment_name}-${local.environment}"
  environment = lower(replace(basename(get_terragrunt_dir()), "[._ ]", "-"))
}