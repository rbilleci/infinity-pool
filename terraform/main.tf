provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project     = "infinity-pool"
      environment = "development"
    }
  }
}

# Create a VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "vpc"
  cidr = "10.0.0.0/16"

  azs = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

# EKS
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.33.1"
  cluster_name    = var.cluster_name
  cluster_version = "1.31"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  eks_managed_node_groups = {
    default = {
      instance_types = ["t4g.nano"]
    }
  }
}

# AURORA
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = var.aurora_cluster_identifier
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  # TODO
  # engine_version          = ""
  master_username         = var.db_username
  master_password         = var.db_password
  storage_encrypted       = true
  backup_retention_period = 0
  vpc_security_group_ids = [module.eks.cluster_security_group_id]
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet.name
  skip_final_snapshot     = true

  serverlessv2_scaling_configuration {
    max_capacity             = 1.0
    min_capacity             = 0.5
    seconds_until_auto_pause = 3600
  }


}
resource "aws_rds_cluster_instance" "aurora" {
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
}

resource "aws_db_subnet_group" "aurora_subnet" {
  name       = "aurora-subnet-group"
  subnet_ids = module.vpc.private_subnets
}
