data "aws_caller_identity" "current" {}


data "aws_eks_cluster" "github_cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

// Add this to your main Terraform file (e.g., main.tf)
data "aws_region" "current" {}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.github_cluster.identity[0].oidc[0].issuer
}
