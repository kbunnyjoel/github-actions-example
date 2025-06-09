output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for *.bunnycloud.xyz"
  value       = aws_acm_certificate.wildcard_certificate.arn
}

output "route53_zone_id" {
  description = "ID of the Route53 hosted zone for bunnycloud.xyz"
  value       = data.aws_route53_zone.bunnycloud.zone_id
}

output "external_dns_role_arn" {
  description = "ARN of the IAM role for ExternalDNS"
  value       = aws_iam_role.external_dns.arn
}