# Minimal cost-efficient EKS cluster using Terraform

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}


terraform {
  backend "s3" {
    bucket       = "my-eks-terraform-state-806210429052"
    key          = "eks/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true # NEW in v1.3+
    encrypt      = true
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  subnet_ids      = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id
  # API access settings
  cluster_endpoint_public_access  = false  # or true to enable public API access
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    spot-nodes = {
    desired_size   = 1
    min_size       = 0
    max_size       = 2
    instance_types = ["t3.small", "t3.medium", "t3a.small"]
    capacity_type  = "SPOT"
    }
  }
  
  #   eks_managed_node_groups = {
  #   default-on-demand = {
  #   desired_size   = 1
  #   min_size       = 1
  #   max_size       = 2
  #   instance_types = ["t3.medium"]
  #   capacity_type  = "ON_DEMAND"
  #   }
  # }

  enable_irsa = true
}
