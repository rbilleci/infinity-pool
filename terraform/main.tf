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
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled = true
    node_pools = ["general-purpose"]
  }
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


# Private DNS (for access to Aurora)
resource "aws_route53_zone" "private" {
  name          = "infinity-pool.internal"
  force_destroy = true
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

#---------------------------------------------------------------------------------------------------------------------
# AURORA Credentials
resource "random_password" "db_password" {
  length  = 30
  special = false
}
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "db-credentials" # Preferably, prefix with environment id to allow multiple deployments per account
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    db_username = "postgres",
    db_password = random_password.db_password.result
  })
}
data "aws_secretsmanager_secret" "db_credentials" {
  depends_on = [aws_secretsmanager_secret_version.db_credentials_version]
  name = "db-credentials"
}
data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)
  db_username = local.db_credentials["db_username"]
  db_password = local.db_credentials["db_password"]
}


#---------------------------------------------------------------------------------------------------------------------
# ROLE W/SECRETS ACCESS
data "aws_iam_openid_connect_provider" "eks" {
  url = module.eks.cluster_oidc_issuer_url
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values = ["system:serviceaccount:default:svc-account"]
    }
  }
}
resource "aws_iam_role" "svc_role" {
  name               = "svc-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
data "aws_iam_policy_document" "service_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"]  # Replace "*" with specific ARNs if you want to restrict access.
  }
}
resource "aws_iam_role_policy" "service_policy_attachment" {
  name   = "ServicePolicy"
  role   = aws_iam_role.svc_role.id
  policy = data.aws_iam_policy_document.service_policy.json
}

#---------------------------------------------------------------------------------------------------------------------
# AURORA
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = var.aurora_cluster_identifier
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  database_name = "postgres" # initial database name
  master_username         = local.db_username
  master_password         = local.db_password
  port                    = 5432
  storage_encrypted       = true
  backup_retention_period = 1
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet.name
  skip_final_snapshot     = true
  vpc_security_group_ids = [module.eks.cluster_primary_security_group_id]
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_to_aurora" {
  security_group_id = module.eks.cluster_primary_security_group_id
  referenced_security_group_id = module.eks.cluster_primary_security_group_id
  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
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


# AURORA DNS RECORD
resource "aws_route53_record" "aurora_db" {
  zone_id = aws_route53_zone.private.zone_id
  name = "db"   # This will create db.<myapp>.internal
  type    = "CNAME"
  ttl     = 30
  records = [aws_rds_cluster.aurora.endpoint]
}


# ECR
resource "aws_ecr_repository" "infinity-pool" {
  name         = "infinity-pool"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
}