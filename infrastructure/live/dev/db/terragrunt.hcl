include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/db"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc"
    private_subnets = ["subnet-a", "subnet-b", "subnet-c"]
    db_subnets = ["subnet-db-a", "subnet-db-b", "subnet-db-c"]
  }
}

inputs = {
  db_cluster_identifier = "db-${include.root.locals.deployment_key}"
  db_subnets            = toset(dependency.vpc.outputs.db_subnets)
  private_subnets       = toset(dependency.vpc.outputs.private_subnets)
  vpc_id                = dependency.vpc.outputs.vpc_id
}