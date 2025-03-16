terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}
# Database Cluster
resource "aws_rds_cluster" "db" {
  cluster_identifier      = var.db_cluster_identifier
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  database_name           = "postgres"
  master_username         = local.db_username
  master_password         = local.db_password
  port                    = 5432
  storage_encrypted       = true
  backup_retention_period = 1
  db_subnet_group_name    = aws_db_subnet_group.db_subnets.name
  skip_final_snapshot     = true
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

# Database Subnets
resource "aws_db_subnet_group" "db_subnets" {
  name       = "db-subnet-group"
  subnet_ids = var.db_subnets
}

# Database Security Group
resource "aws_security_group" "db_security_group" {
  name   = "${var.db_cluster_identifier}-security-group"
  vpc_id = var.vpc_id
}

# Retrieve details (including CIDR block) for each subnet ID.
data "aws_subnet" "selected" {
  for_each = toset(var.private_subnets)

  id = each.value
}

# For each private subnet, create an ingress rule to allow
# access to the database on its port
resource "aws_vpc_security_group_ingress_rule" "db_private_subnet_ingress_rule" {
  # FOR EACH SUBNET
  for_each = data.aws_subnet.selected

  description       = "Allow ingress from subnet ${each.key}"
  security_group_id = aws_security_group.db_security_group.id
  cidr_ipv4         = each.value.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

# Database Credentials
# 1. Generate a random password
# 2. Configure a new secret in the AWS Secrets Manager
# 3. Store the Database username and password  in the AWS Secrets Manager
resource "random_password" "db_password" {
  length  = 30
  special = false
}

# TODO: Preferably, prefix with environment id to allow multiple deployments per account
# TODO: mismatch between 'db-credentials and db_credentials... confusing'
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "db-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    # TODO: parameterize username
    db_username = "postgres",
    db_password = random_password.db_password.result
  })
}

# Retrieve the Database credentials from the secret
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


