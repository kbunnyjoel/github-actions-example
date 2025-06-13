# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.argocd_pool.id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.argocd_client.id
}

output "cognito_user_pool_domain" {
  description = "The domain name of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.argocd_domain.domain
}

output "cognito_user_pool_endpoint" {
  description = "The endpoint URL of the Cognito User Pool"
  value       = "https://${aws_cognito_user_pool_domain.argocd_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
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