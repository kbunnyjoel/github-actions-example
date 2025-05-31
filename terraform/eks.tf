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
  cluster_version = "1.29"

  # Use both private and public subnets for better connectivity
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  vpc_id = module.vpc.vpc_id

  # API access settings
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Add cluster security group rules for external DNS
  cluster_security_group_additional_rules = {
    egress_dns_tcp = {
      description = "Allow DNS resolution (TCP)"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_dns_udp = {
      description = "Allow DNS resolution (UDP)"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_https = {
      description = "Allow HTTPS outbound"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  eks_managed_node_groups = {
    spot-nodes = {
      desired_size   = 1 # Reduce from 2 to 1 for initial deployment
      min_size       = 1
      max_size       = 3
      instance_types = ["t3a.medium", "t3.medium"] # Use AMD-based instances first
      capacity_type  = "SPOT"
      key_name       = aws_key_pair.deployment_key.key_name

      # Add labels to identify these nodes
      labels = {
        role = "worker"
        type = "spot"
      }

      # Add tags specific to this node group
      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true"
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
        "NodeGroup"                                     = "spot-nodes"
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

  # Add IAM policies with least privilege principle
  create_cluster_security_group = true
  create_node_security_group    = true
  node_security_group_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}


# Create IAM role for cluster autoscaler
resource "aws_iam_role" "cluster_autoscaler" {
  name = "eks-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Create IAM policy for cluster autoscaler
resource "aws_iam_policy" "cluster_autoscaler_role_policy" {
  name        = "eks-cluster-autoscaler-policy"
  description = "EKS cluster autoscaler policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cluster_autoscaler_role_policy" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler_role_policy.arn
}
