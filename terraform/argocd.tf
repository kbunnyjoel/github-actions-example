resource "aws_iam_role" "argocd_role" {
  name = "argocd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.github_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.github_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:argocd:argocd-server"
          }
        }
      }
    ]
  })

  tags = {
    Name = "argocd-role"
  }
}

resource "aws_iam_policy" "argocd_policy" {
  name        = "argocd-policy"
  description = "Policy for ArgoCD to access AWS resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd_policy_attachment" {
  role       = aws_iam_role.argocd_role.name
  policy_arn = aws_iam_policy.argocd_policy.arn
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "alb_controller_role" {
  name = "eks-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = module.eks.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.github_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}
