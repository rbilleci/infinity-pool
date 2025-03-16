include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  enable_nat_gateway     = true
  deployment_key         = include.root.locals.deployment_key
  one_nat_gateway_per_az = false
  single_nat_gateway     = true
  vpc_name               = "vpc-${include.root.locals.deployment_key}"
}
