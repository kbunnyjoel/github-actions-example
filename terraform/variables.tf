variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "ap-southeast-2" # Sydney
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "github-actions-eks-example"
}
