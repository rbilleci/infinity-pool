include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/ecr"
}

inputs = {
  ecr_repository_name = "${include.root.locals.deployment_key}"
  deployment_key      = include.root.locals.deployment_key
}