include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc"
    private_subnets = ["subnet-a", "subnet-b", "subnet-c"]
  }
}

inputs = {
  cluster_name      = "eks-${include.root.locals.deployment_key}"
  cluster_version   = "1.32"
  private_subnets = toset(dependency.vpc.outputs.private_subnets)
  service_role_name = "${include.root.locals.deployment_key}-service-role"
  vpc_id            = dependency.vpc.outputs.vpc_id
}