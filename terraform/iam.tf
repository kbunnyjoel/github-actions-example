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
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchTemplates" # Added for launch templates
        ],
        Effect   = "Allow",
        Resource = "*" # Describe actions require * resource
      },
      {
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup" # Crucial for modifying min/max size
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

# ---------------------------------------------------------------------------------------------------------------------
# COGNITO IAM PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------

# IAM role for ArgoCD to authenticate with Cognito
resource "aws_iam_role" "argocd_cognito_auth" {
  name = "argocd-cognito-auth-role"

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
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:argocd:argocd-server"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "argocd-cognito-auth-role"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

# Policy for ArgoCD to access Cognito
resource "aws_iam_policy" "argocd_cognito_policy" {
  name        = "argocd-cognito-policy"
  description = "Policy for ArgoCD to authenticate with Cognito"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cognito-idp:DescribeUserPool",
          "cognito-idp:DescribeUserPoolClient",
          "cognito-idp:ListUserPoolClients",
          "cognito-idp:ListUsers",
          "cognito-idp:ListGroups",
          "cognito-idp:ListUsersInGroup",
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:AdminRespondToAuthChallenge"
        ],
        Effect   = "Allow",
        Resource = aws_cognito_user_pool.argocd_pool.arn
      },
      {
        Action = [
          "ssm:GetParameter"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/k8s/argocd/cognito/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "argocd-cognito-policy"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

resource "aws_iam_role_policy_attachment" "argocd_cognito" {
  role       = aws_iam_role.argocd_cognito_auth.name
  policy_arn = aws_iam_policy.argocd_cognito_policy.arn
}

# Policy for creating and managing SSM parameters
resource "aws_iam_policy" "ssm_parameter_policy" {
  name        = "ssm-parameter-management-policy"
  description = "Policy for creating and managing SSM parameters for Cognito"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/k8s/argocd/cognito/*"
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ],
        Effect   = "Allow",
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:ViaService" : "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "ssm-parameter-management-policy"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

# Attach the SSM parameter policy to the Terraform execution role
# This assumes you're using a role for Terraform execution
# If you're using AWS credentials directly, you'll need to attach this policy to your IAM user
# Create a variable for the Terraform execution role name
variable "terraform_execution_role" {
  description = "The IAM role used for Terraform execution"
  type        = string
  default     = null # Set to null by default, requiring explicit assignment
}

# Note: When using AWS credentials directly, ensure your IAM user/role
# has the permissions defined in ssm_parameter_policy

# Note: The Kubernetes service account will be created by the GitHub Actions workflow
# using the service-account.yaml template, not by Terraform directly.

# ---------------------------------------------------------------------------------------------------------------------
# EKS NODE LOAD BALANCER SERVICE POLICY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_policy" "node_load_balancer_policy" {
  name        = "eks-node-load-balancer-policy"
  description = "Allows EKS nodes to create and manage Load Balancers for services"

  # Policy based on AWS documentation for the legacy in-tree cloud provider
  # to manage LoadBalancer services.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:RemoveTags"
        ],
        Resource = "*"
      }
    ]
  })
}
# This avoids the connection refused error when Terraform tries to connect to Kubernetes.
