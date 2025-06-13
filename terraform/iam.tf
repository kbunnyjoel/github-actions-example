# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLES AND POLICIES
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# EKS VPC CNI
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "vpc_cni" {
  name = "eks-vpc-cni-role"

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
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "eks-vpc-cni-role"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS CLUSTER AUTOSCALER
# ---------------------------------------------------------------------------------------------------------------------

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

  tags = {
    Name        = "eks-cluster-autoscaler"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
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
          "autoscaling:DescribeTags"
        ],
        Effect   = "Allow",
        Resource = "*" # Describe actions require * resource
      },
      {
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/eks-*"
      },
      {
        Action = [
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*"
      }
    ]
  })

  tags = {
    Name        = "eks-cluster-autoscaler-policy"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}

resource "aws_iam_user" "argocd_users" {
  for_each = toset(["user1", "user2", "admin1"])
  name     = each.key
}
