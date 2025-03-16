module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"
  name    = var.vpc_name
  cidr = "10.0.0.0/16"

  # NAT
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # DNS
  enable_dns_hostnames = true
  enable_dns_support = true

  # AZs
  azs = [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c"
  ]

  # Subnets
  public_subnets = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  private_subnets = [
    "10.0.100.0/24",
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
  database_subnets = [
    "10.0.200.0/24",
    "10.0.201.0/24",
    "10.0.202.0/24"
  ]
  # VPN
  enable_vpn_gateway = false
  # Tag Required by EKS AutoMode
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  # Tag Required by EKS AutoMode
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}