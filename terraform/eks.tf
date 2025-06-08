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
  map_public_ip_on_launch = false
  enable_nat_gateway      = true
  single_nat_gateway      = true

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # Enable VPC Flow Logs
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 14
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = ">=20.35.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  # Add these security configurations
  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  # Enable EKS control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Use both private and public subnets for better connectivity
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  vpc_id = module.vpc.vpc_id

  # API access settings
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # Add cluster security group rules for external DNS
  cluster_security_group_additional_rules = {
    egress_dns_tcp = {
      description = "Allow DNS resolution (TCP)"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    egress_dns_udp = {
      description = "Allow DNS resolution (UDP)"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    egress_https = {
      description = "Allow HTTPS outbound"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  node_security_group_additional_rules = {
    egress_internal = {
      description = "Allow internal traffic"
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [module.vpc.vpc_cidr_block] # restrict to internal network only
    }

    # Allow specific external access for required services
    egress_ntp_tcp = {
      description = "Allow NTP TCP"
      protocol    = "tcp"
      from_port   = 123
      to_port     = 123
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress_ntp_udp = {
      description = "Allow NTP UDP"
      protocol    = "udp"
      from_port   = 123
      to_port     = 123
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress_https = {
      description = "Allow HTTPS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress_dns_tcp = {
      description = "Allow DNS TCP"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress_dns_udp = {
      description = "Allow DNS UDP"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  eks_managed_node_groups = {
    spot-nodes = {
      desired_size   = 1
      min_size       = 1
      max_size       = 3
      instance_types = ["t3a.medium", "t3.medium"]
      capacity_type  = "SPOT"
      key_name       = aws_key_pair.deployment_key.key_name

      # Add labels to identify these nodes
      labels = {
        role = "worker"
        type = "spot"
      }

      # Add block device mappings with delete_on_termination
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            delete_on_termination = true
            volume_size           = 20
            volume_type           = "gp3"
          }
        }
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

  # Add these lines for proper cleanup
  cluster_security_group_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  node_security_group_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}


# Configure the VPC CNI add-on to delete ENIs on termination
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  # Use a simpler configuration without the unsupported parameter
  configuration_values = jsonencode({
    env = {
      WARM_ENI_TARGET = "0"
      WARM_IP_TARGET  = "0"
    }
  })

  depends_on = [module.eks]
}

# Create KMS key for EKS secrets encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "eks-secrets-key"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/eks-secrets"
  target_key_id = aws_kms_key.eks.key_id
}
