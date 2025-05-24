# Minimal cost-efficient EKS cluster using Terraform

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket        = "my-eks-terraform-state-${data.aws_caller_identity.current.account_id}"
    key           = "eks/terraform.tfstate"
    region        = "ap-southeast-2"
    use_lockfile  = true # NEW in v1.3+
    encrypt       = true
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

  eks_managed_node_groups = {
    spot-nodes = {
      desired_size = 1
      max_size     = 2
      min_size     = 0

      instance_types = ["t3.small", "t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  enable_irsa = true
}
