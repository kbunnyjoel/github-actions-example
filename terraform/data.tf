data "aws_caller_identity" "current" {}


data "aws_eks_cluster" "github_cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_region" "current" {
  name = var.aws_region
}

data "aws_route53_zone" "main" {
  zone_id = "Z0722775AO3VTQLFVQU3"
}
