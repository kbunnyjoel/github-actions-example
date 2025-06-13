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

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "argocd_role_arn" {
  value = aws_iam_role.argocd_role.arn
}

output "cognito_client_secret" {
  value     = aws_cognito_user_pool_client.argocd.client_secret
  sensitive = true
}

output "cognito_issuer_url" {
  value = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.argocd.id}"
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.argocd.id
}

output "cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.argocd.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "cognito_users" {
  value = {
    admin = {
      username = aws_cognito_user.admin_user.username
      email    = "admin@example.com"
      password = "Temp123!" # Note: In production, don't output passwords
    }
    developer = {
      username = aws_cognito_user.dev_user.username
      email    = "dev@example.com"
      password = "Temp123!" # Note: In production, don't output passwords
    }
  }
  sensitive = true
}
