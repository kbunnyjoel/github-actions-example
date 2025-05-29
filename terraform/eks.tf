# Minimal cost-efficient EKS cluster using Terraform

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Using the main Route53 zone defined in bastion.tf


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
  version = ">= 5.21.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = ">=20.35.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.29" # Example: Use a currently supported EKS version. Please verify the latest.
  # subnet_ids      = module.vpc.public_subnets
  subnet_ids = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id
  # API access settings
  cluster_endpoint_public_access  = true # or true to enable public API access
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    spot-nodes = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.large", "t3.medium"]            # Larger instance types for better pod capacity
      capacity_type  = "SPOT"                               # Cost-efficient for non-critical workloads
      key_name       = aws_key_pair.deployment_key.key_name # For SSH access via bastion
      
      # Add labels to identify these nodes
      labels = {
        role = "worker"
        type = "spot"
      }
      
      # Add tags specific to this node group
      tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
        "NodeGroup" = "spot-nodes"
      }
    }
  }
  tags = {
    Environment = "dev"
    Project     = "github-actions-example"
  }


  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_irsa                              = true
}
