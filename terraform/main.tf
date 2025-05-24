# Minimal cost-efficient EKS cluster using Terraform

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
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




# .github/workflows/eks-terraform.yml
# ------------------------------------
# name: Provision EKS with Terraform

# on:
#   push:
#     paths:
#       - 'terraform/**'
#     branches: [main]
#   workflow_dispatch:

# jobs:
#   terraform-eks:
#     runs-on: ubuntu-latest

#     defaults:
#       run:
#         working-directory: terraform

#     steps:
#       - name: Checkout repository
#         uses: actions/checkout@v4

#       - name: Configure AWS credentials
#         uses: aws-actions/configure-aws-credentials@v3
#         with:
#           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
#           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
#           aws-region: ap-southeast-2

#       - name: Install Terraform
#         uses: hashicorp/setup-terraform@v3
#         with:
#           terraform_version: 1.6.6

#       - name: Terraform Init
#         run: terraform init

#       - name: Terraform Plan
#         run: terraform plan

#       - name: Terraform Apply (Auto-Approve)
#         run: terraform apply -auto-approve
