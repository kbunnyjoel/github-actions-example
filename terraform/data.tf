data "aws_caller_identity" "current" {}


data "aws_eks_cluster" "github_cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_region" "current" {
  name = var.aws_region
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.github_cluster.identity[0].oidc[0].issuer
}
