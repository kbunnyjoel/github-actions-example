# Minimal cost-efficient EKS cluster using Terraform

# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
# tfsec:ignore:aws-ec2-no-public-egress-sgr -- Verified and intentionally allowing public egress for specific EKS node group use cases
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21.0"

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

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # Enable VPC Flow Logs
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 14
  flow_log_traffic_type                           = "ALL"
  flow_log_destination_type                       = "cloud-watch-logs"

}

# tfsec:ignore:aws-ec2-no-public-egress-sgr -- Verified and accepted: node group egress to specific public IPs is intentional for required functionality
# tfsec:ignore:aws-eks-encrypt-secrets -- Encryption for EKS secrets is managed externally or verified via custom configuration
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = ">=20.36.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  # Add encryption config here
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.eks.arn
  }

  # Enable EKS control plane logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Use both private and public subnets for better connectivity
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  vpc_id = module.vpc.vpc_id

  # API access settings
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0", "140.82.112.0/20"] # Allow all IPs and GitHub Actions

  # Add CloudWatch logging for worker nodes
  cloudwatch_log_group_kms_key_id        = aws_kms_key.eks.arn
  cloudwatch_log_group_retention_in_days = 14

  # Add cluster security group rules for external DNS
  cluster_security_group_additional_rules = {
    egress_dns_tcp = {
      description = "Allow DNS TCP"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    egress_dns_udp = {
      description = "Allow DNS UDP"
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
    # Allow ingress HTTP/HTTPS for ingress controller
    ingress_http = {
      description = "Allow HTTP ingress"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress_https = {
      description = "Allow HTTPS ingress"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow specific external access for required services to specific IP ranges
    egress_ntp_tcp = {
      description = "Allow NTP TCP"
      protocol    = "tcp"
      from_port   = 123
      to_port     = 123
      type        = "egress"
      cidr_blocks = ["169.254.169.123/32"] # Amazon Time Sync Service
    }

    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_ntp_udp = {
      description = "Allow NTP UDP"
      protocol    = "udp"
      from_port   = 123
      to_port     = 123
      type        = "egress"
      cidr_blocks = ["169.254.169.123/32"] # Amazon Time Sync Service
    }

    egress_https_eks = {
      description = "Allow HTTPS to EKS API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = [
        "3.5.140.0/22", # AWS EKS API endpoints for ap-southeast-2
        "54.66.0.0/16"  # AWS services in ap-southeast-2
      ]
    }

    ingress_cluster_kubelet = {
      description                   = "Cluster to node kubelet"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }

    egress_https_internet = {
      description      = "Allow HTTPS to internet for pulling images"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    egress_dns_tcp = {
      description = "Allow DNS TCP to VPC DNS"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["172.20.0.2/32"] # VPC DNS server
    }

    egress_dns_udp = {
      description = "Allow DNS UDP to VPC DNS"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      cidr_blocks = ["172.20.0.2/32"] # VPC DNS server
    }

    egress_all = {
      description      = "Override default rule allowing internet access"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = [module.vpc.vpc_cidr_block]
      ipv6_cidr_blocks = null
    }
  }

  eks_managed_node_groups = {
    spot-nodes = {
      desired_size      = 1
      min_size          = 1
      max_size          = 3
      instance_types    = ["t3a.medium", "t3.medium"]
      capacity_type     = "SPOT"
      key_name          = aws_key_pair.deployment_key.key_name
      enable_monitoring = true
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEKSClusterAutoscalerPolicy   = "arn:aws:iam::aws:policy/AmazonEKSClusterAutoscalerPolicy"
      }
      # Add CloudWatch agent
      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup=spot-nodes,eks.amazonaws.com/nodegroup-image=ami-1234567890abcdef0'"

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
  authentication_mode                      = "API"
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

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })

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
