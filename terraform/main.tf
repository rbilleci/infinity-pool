provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      project     = "infinity-pool"
      environment = "development"
    }
  }
}

terraform {
  backend "s3" {}
}

# AWS Account ID
data "aws_caller_identity" "current" {}

# VPC
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.19.0"
  name                 = "vpc"
  cidr                 = "10.0.0.0/16"
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_vpn_gateway   = false
  azs = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  database_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# EKS
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.34.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.32"
  vpc_id = module.vpc.vpc_id
  # EKS Auto Mode
  cluster_compute_config = {
    enabled = true
    node_pools = ["general-purpose"]
  }
  subnet_ids = module.vpc.private_subnets
  # Allow management from local computer
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    access_entry = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      policy_associations = {
        view_cluster = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
            namespaces = []
          }
        }
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
            namespaces = []
          }
        }
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
            namespaces = []
          }
        }
      }
    }
  }
}

# AURORA
resource "aws_rds_cluster" "aurora" {
  cluster_identifier   = var.aurora_cluster_identifier
  engine               = "aurora-postgresql"
  engine_mode          = "provisioned"
  master_username      = var.db_username
  master_password      = var.db_password
  storage_encrypted    = true
  backup_retention_period = 1
  #vpc_security_group_ids = [module.eks.cluster_security_group_id]
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet.name
  skip_final_snapshot  = true

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
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
  subnet_ids = module.vpc.database_subnets
}