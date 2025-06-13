resource "aws_iam_role" "argocd_role" {
  name = "argocd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:argocd:argocd-server"
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


resource "aws_cognito_user_pool" "argocd" {
  name = "argocd-users"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "argocd" {
  name         = "argocd-client"
  user_pool_id = aws_cognito_user_pool.argocd.id

  allowed_oauth_flows          = ["code"]
  allowed_oauth_scopes         = ["email", "openid", "profile"]
  callback_urls                = ["https://argocd.bunnycloud.xyz/auth/callback"]
  supported_identity_providers = ["COGNITO"]

  generate_secret = true
}

resource "aws_cognito_user_pool_domain" "argocd" {
  domain       = "argocd-auth"
  user_pool_id = aws_cognito_user_pool.argocd.id
}
