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

variable "kubectl_version" {
  type        = string
  default     = "v1.33.0"
  description = "The version of kubectl to install"
}

variable "helm_version" {
  type        = string
  description = "Version of Helm to install on the bastion host"
  default     = "v3.14.0"
}
