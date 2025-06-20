output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.argocd_pool.id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.argocd_client.id
}

output "cognito_user_pool_endpoint" {
  description = "The endpoint URL of the Cognito User Pool"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.argocd_pool.id}"
}

output "argocd_cognito_role_arn" {
  description = "The ARN of the IAM role for ArgoCD to authenticate with Cognito"
  value       = aws_iam_role.argocd_cognito_auth.arn
}

output "ssm_parameter_paths" {
  description = "The paths to the SSM parameters containing temporary passwords"
  value = {
    admin = aws_ssm_parameter.admin_temp_password.name
    dev   = aws_ssm_parameter.dev_temp_password.name
  }
  sensitive = true
}

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
  description = "ARN of the ACM certificate for *.bunnycloud.xyz in ap-southeast-2 (for EKS Load Balancers)"
  value       = aws_acm_certificate.wildcard_certificate_ap_southeast_2.arn
}

output "acm_certificate_arn_us_east_1" {
  description = "ARN of the ACM certificate for *.bunnycloud.xyz in us-east-1 (e.g., for CloudFront)"
  value       = aws_acm_certificate.wildcard_certificate_us_east_1.arn
}

output "route53_zone_id" {
  description = "ID of the Route53 hosted zone for bunnycloud.xyz"
  value       = aws_route53_zone.main.zone_id
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
  description = "The client secret for the Cognito User Pool Client ('argocd_client' from cognito.tf). This is managed in AWS Secrets Manager."
  value       = "Stored in AWS Secrets Manager: ${aws_secretsmanager_secret.argocd_cognito_client_secret.name}" # Informational, actual value not outputted
  sensitive   = true
}

output "cognito_client_id" {
  description = "The ID of the Cognito User Pool Client ('argocd_client' from cognito.tf)"
  value       = aws_cognito_user_pool_client.argocd_client.id # Ensure this points to the client in cognito.tf
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

output "cognito_oidc_issuer_url" {
  description = "OIDC issuer URL for Cognito"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.argocd_pool.id}"
}

output "cognito_hosted_ui_domain" {
  description = "The domain for the Cognito Hosted UI (e.g., https://<prefix>.auth.<region>.amazoncognito.com)"
  value       = "https://${aws_cognito_user_pool_domain.cognito_amazon_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller_role.arn
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler_role.arn
}
