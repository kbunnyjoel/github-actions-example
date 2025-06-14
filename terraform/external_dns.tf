resource "aws_iam_policy" "external_dns" {
  name        = "eks-external-dns-policy"
  description = "Policy for ExternalDNS to access Route 53"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "route53:ChangeResourceRecordSets"
        ],
        Resource = [aws_route53_zone.main.arn]
      },
      {
        Effect = "Allow",
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        Resource = ["*", aws_route53_zone.main.arn]
      }
    ]
  })
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.github_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "external_dns" {
  name = "eks-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.this.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${data.aws_iam_openid_connect_provider.this.url}:sub" = "system:serviceaccount:external-dns:external-dns",
            "${data.aws_iam_openid_connect_provider.this.url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}
