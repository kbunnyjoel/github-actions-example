data "aws_region" "current" {
  name = var.aws_region
}

data "aws_caller_identity" "current" {}

# Use this after the cluster is created
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}
