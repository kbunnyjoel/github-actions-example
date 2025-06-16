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
  description = "Version of kubectl to install on the bastion host"
  type        = string
  default     = "v1.29.0"
}

variable "helm_version" {
  description = "Version of Helm to install on the bastion host"
  type        = string
  default     = "v3.14.4"
}

variable "create_dns_records" {
  description = "Whether to create DNS records"
  type        = bool
  default     = true
}

# ACM certificate ARN for Cognito custom domain
variable "acm_cert_arn" {
  description = "ARN of the ACM certificate for custom Cognito domain"
  type        = string
}

variable "cognito_custom_domain" {
  description = "The custom domain to associate with the Cognito user pool (e.g., auth.bunnycloud.xyz)"
  type        = string
}
