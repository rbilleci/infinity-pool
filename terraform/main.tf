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
}

# EKS
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.34.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.32"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  eks_managed_node_groups = {
    default = {
      ami_type = "AL2023_ARM_64_STANDARD" # Use of ARM instances
      instance_types = ["t4g.micro"] # Use instance types with a minimum of 1GB RAM
    }
  }
  # Allow management from local computer
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
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


# Public Load Balancer
resource "aws_lb" "public_alb" {
  name               = "lb-public"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups = [aws_security_group.alb_sg.id]
  internal           = false
}

resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}

resource "aws_lb_target_group" "public_tg" {
  name     = "${aws_lb.public_alb.name}-tg"
  vpc_id   = module.vpc.vpc_id
  port     = 80
  protocol = "HTTP"
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for the public ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

